{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.local.wireguardRouting;

  # NM dispatcher runs with a minimal environment, so everything is absolute.
  ip = "${pkgs.iproute2}/bin/ip";
  nmcli = "${pkgs.networkmanager}/bin/nmcli";
  resolvectl = "${pkgs.systemd}/bin/resolvectl";
  awk = "${pkgs.gawk}/bin/awk";
  sed = "${pkgs.gnused}/bin/sed";
  getent = "${pkgs.getent}/bin/getent";
  logger = "${pkgs.util-linux}/bin/logger";

  metaCase = lib.concatMapStrings (c: ''
    ${c.name})
        printf '%s %s %s %s\n' ${toString c.table} ${toString c.mark} ${lib.escapeShellArg c.endpoint} ${
          if c.dnssec then "yes" else "no"
        }
        ;;
  '') cfg.connections;

  script = pkgs.writeText "wireguardRouteHelper" ''
    #!${pkgs.bash}/bin/bash
    IFACE="$1"
    ACTION="$2"

    # Endpoint addresses currently pinned to the physical uplink, one file per
    # interface, so "down" can remove exactly what "up" installed.
    STATE_DIR=/run/wg-route-helper
    ${pkgs.coreutils}/bin/mkdir -p "$STATE_DIR"

    log() {
        ${logger} -t wg-route-helper "$*"
    }

    # table, fwmark, endpoint and DNSSEC flag for every managed tunnel
    wg_meta() {
        case "$1" in
        ${metaCase}
            *)
                return 1
                ;;
        esac
    }

    # endpoint is host:port or [v6addr]:port
    strip_port() {
        case "$1" in
            \[*\]:*)
                local trimmed="''${1%]:*}"
                printf '%s\n' "''${trimmed#[}"
                ;;
            *:*)
                printf '%s\n' "''${1%:*}"
                ;;
            *)
                printf '%s\n' "$1"
                ;;
        esac
    }

    # Returns "<device> <gateway>" for the physical uplink with the best default
    # route. Asking NetworkManager for the device type instead of reading the
    # routing table keeps this correct regardless of whether another VPN has
    # already installed its own default route.
    physical_uplink() {
        local dev type state metric gw best="" best_metric=4294967295

        while IFS=: read -r dev type state; do
            case "$type" in
                ethernet|wifi) ;;
                *) continue ;;
            esac
            [ "$state" = "connected" ] || continue

            metric=$(${ip} -4 -o route show default dev "$dev" \
                | ${sed} -n 's/.*metric \([0-9]*\).*/\1/p' | ${pkgs.coreutils}/bin/head -n1)
            [ -n "$metric" ] || metric=0

            if [ "$metric" -lt "$best_metric" ]; then
                best_metric="$metric"
                best="$dev"
            fi
        done < <(${nmcli} -t -f DEVICE,TYPE,STATE device status)

        [ -n "$best" ] || return 1

        gw=$(${ip} -4 -o route show default dev "$best" \
            | ${sed} -n 's/.*via \([0-9.]*\).*/\1/p' | ${pkgs.coreutils}/bin/head -n1)
        printf '%s %s\n' "$best" "$gw"
    }

    # The encapsulated packets carry the tunnel's fwmark, so they bypass the
    # tunnel's own rule and resolve in the main table. Without an explicit host
    # route they follow whatever default route another full-tunnel VPN installed,
    # which would nest this tunnel inside that VPN.
    pin_endpoint() {
        local iface="$1" meta host addr dev gw
        meta=$(wg_meta "$iface") || return 0
        host=$(strip_port "$(printf '%s\n' "$meta" | ${awk} '{print $3}')")

        addr=$(${getent} ahostsv4 "$host" | ${awk} '{print $1; exit}')
        if [ -z "$addr" ]; then
            log "$iface: cannot resolve endpoint $host, not pinning"
            return 0
        fi

        read -r dev gw < <(physical_uplink)
        if [ -z "$dev" ]; then
            log "$iface: no physical uplink found, endpoint $addr not pinned"
            return 0
        fi

        if [ -n "$gw" ]; then
            ${ip} -4 route replace "$addr/32" via "$gw" dev "$dev" metric 1
        else
            ${ip} -4 route replace "$addr/32" dev "$dev" scope link metric 1
        fi
        printf '%s\n' "$addr" > "$STATE_DIR/$iface.endpoint"
        log "$iface: endpoint $addr pinned to $dev''${gw:+ via $gw}"
    }

    unpin_endpoint() {
        local iface="$1" addr
        [ -f "$STATE_DIR/$iface.endpoint" ] || return 0
        addr=$(< "$STATE_DIR/$iface.endpoint")
        ${ip} -4 route del "$addr/32" 2>/dev/null
        ${pkgs.coreutils}/bin/rm -f "$STATE_DIR/$iface.endpoint"
    }

    # A roaming event (wifi to ethernet, DHCP renew) invalidates the pinned host
    # route, so redo it for every tunnel that is still up.
    repin_all() {
        local f iface
        for f in "$STATE_DIR"/*.endpoint; do
            [ -e "$f" ] || continue
            iface=$(${pkgs.coreutils}/bin/basename "$f" .endpoint)
            ${ip} link show dev "$iface" >/dev/null 2>&1 || { unpin_endpoint "$iface"; continue; }
            pin_endpoint "$iface"
        done
    }

    if meta=$(wg_meta "$IFACE"); then
        read -r TABLE MARK ENDPOINT DNSSEC <<< "$meta"

        case "$ACTION" in
            up)
                if [ "$TABLE" != 0 ]; then
                    # Route everything that is not already-encapsulated traffic of
                    # this tunnel through the tunnel's own table.
                    ${ip} -4 ru del prio "$TABLE" 2>/dev/null
                    ${ip} -6 ru del prio "$TABLE" 2>/dev/null
                    ${ip} -4 ru add prio "$TABLE" not fwmark "$MARK" lookup "$TABLE"
                    ${ip} -6 ru add prio "$TABLE" not fwmark "$MARK" lookup "$TABLE"
                fi

                if [ "$DNSSEC" = yes ]; then
                    ${resolvectl} dnssec "$IFACE" allow-downgrade
                fi

                pin_endpoint "$IFACE"
                ;;
            down)
                if [ "$TABLE" != 0 ]; then
                    ${ip} -4 ru del prio "$TABLE" 2>/dev/null
                    ${ip} -6 ru del prio "$TABLE" 2>/dev/null
                fi
                unpin_endpoint "$IFACE"
                ;;
        esac
        exit 0
    fi

    case "$ACTION" in
        up|dhcp4-change|dhcp6-change)
            repin_all
            ;;
    esac
  '';
in
{
  options.local.wireguardRouting.connections = lib.mkOption {
    default = [ ];
    description = ''
      WireGuard tunnels the NetworkManager dispatcher helper should manage:
      per-tunnel policy routing and pinning of the tunnel endpoint to the
      physical uplink.
    '';
    type = lib.types.listOf (
      lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "Interface name of the tunnel.";
          };
          table = lib.mkOption {
            type = lib.types.int;
            default = 0;
            description = "Routing table and rule priority; 0 disables policy routing.";
          };
          mark = lib.mkOption {
            type = lib.types.int;
            default = 0;
            description = "fwmark the tunnel stamps on its encapsulated packets.";
          };
          endpoint = lib.mkOption {
            type = lib.types.str;
            description = "Peer endpoint as host:port.";
          };
          dnssec = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable per-link DNSSEC validation (allow-downgrade).";
          };
        };
      }
    );
  };

  config = lib.mkIf (cfg.connections != [ ]) {
    networking.networkmanager.dispatcherScripts = [
      {
        source = script;
        type = "basic";
      }
    ];
  };
}
#  vim: set ts=2 sw=2 tw=0 et :
