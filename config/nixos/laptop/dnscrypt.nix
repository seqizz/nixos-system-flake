# DNS resolution strategy, in order of preference:
#
# 1. VPN routing domains
#    WireGuard/NM VPN links may provide per-link DNS + routing domains.
#    systemd-resolved should still route matching domains to VPN DNS.
#
# 2. Home wifi
#    When connected to HOME_SSID, use DHCP-provided DNS naturally
#    — expected to be pi-hole.
#
# 3. Captive portal / not-yet-full connectivity
#    On unknown/public networks, first keep/restore DHCP DNS.
#    This is required because captive portals often rely on their own DNS
#    for portal detection and login redirection.
#
# 4. Outside networks after full connectivity
#    Once NetworkManager reports FULL connectivity, override the physical
#    link DNS to localhost dnscrypt-proxy.
#
# 5. Fallback
#    If no usable per-link DNS exists, resolved has Quad9 fallback.
#
# Important tradeoff:
# - This intentionally allows a small DHCP DNS window on public networks
#   before captive portal/login/full-connectivity detection completes.
# - If you want zero DNS leak on public networks, automatic captive portal
#   support and that goal conflict; use a manual "portal mode" instead.
#
# Manual escape hatch:
#   sudo touch /run/dnscrypt-override.disabled
#     -> dispatcher will keep DHCP DNS on later events
#
#   sudo rm /run/dnscrypt-override.disabled
#     -> normal policy resumes on later events
#
# Notes:
# - NetworkManager connectivity checking must be enabled for this to work.
# - Replace the connectivity URI with your own endpoint if you dislike
#   using the GNOME one.
# - dnscrypt-proxy lifecycle is owned by this dispatcher (not autostarted by
#   systemd). It is only started when NM reports FULL connectivity on a
#   non-home network and the override is not disabled. Captive portals would
#   otherwise poison its internal state by blocking upstream resolvers.

{
  config,
  lib,
  pkgs,
  ...
}:
let
  secrets = import ../secrets.nix;
in
{
  services.resolved = {
    enable = true;
    settings.Resolve.FallbackDNS = [ "9.9.9.9" ];
  };

  # Don't let dnscrypt-proxy module set global DNS, we manage per-link DNS.
  networking.nameservers = lib.mkForce [ ];

  # Enable NM connectivity state, needed to distinguish FULL vs PORTAL/LIMITED.
  networking.networkmanager.settings.connectivity = {
    enabled = true;
    uri = "http://nmcheck.gnome.org/check_network_status.txt";
    interval = 60;
    timeout = 5;
  };

  # Dispatcher owns the service lifecycle (start on FULL non-home, stop otherwise).
  # Prevents the proxy from thrashing/poisoning state during captive portal phase.
  systemd.services.dnscrypt-proxy.wantedBy = lib.mkForce [ ];

  # upstreamDefaults = true (default) provides sane source list, keys, and URLs
  services.dnscrypt-proxy = {
    enable = true;
    settings = {
      listen_addresses = [
        "127.0.0.1:53"
        "[::1]:53"
      ];
      server_names = [
        "scaleway-fr"
        "quad9-dnscrypt-ip4-nofilter-pri"
        "dnscrypt.eu-dk"
      ];
      require_nolog = true;
      require_nofilter = true;
      cache = true;
      cache_size = 512;
      cache_min_ttl = 60;
      cache_max_ttl = 720;
    };
  };

  networking.networkmanager.dispatcherScripts = [
    {
      source = pkgs.writeText "dnscrypt-override" ''
        #!/usr/bin/env ${pkgs.bash}/bin/bash

        HOME_SSID="${secrets.homeSSID}"
        DISABLE_FILE="/run/dnscrypt-override.disabled"

        log() {
          ${pkgs.util-linux}/bin/logger -t dnscrypt-override "$*"
        }

        connection_id_for_iface() {
          local iface="$1"

          if [[ -n "''${CONNECTION_ID:-}" && "$iface" == "''${DEVICE_IP_IFACE:-$iface}" ]]; then
            printf '%s\n' "''${CONNECTION_ID}"
            return 0
          fi

          ${pkgs.networkmanager}/bin/nmcli -g GENERAL.CONNECTION device show "$iface" 2>/dev/null \
            | ${pkgs.coreutils}/bin/head -n1
        }

        is_physical_iface() {
          local iface="$1"
          local type

          [[ -n "$iface" ]] || return 1

          type="$(${pkgs.networkmanager}/bin/nmcli -g GENERAL.TYPE device show "$iface" 2>/dev/null \
            | ${pkgs.coreutils}/bin/head -n1)"

          [[ "$type" == "wifi" || "$type" == "ethernet" ]]
        }

        connected_physical_ifaces() {
          ${pkgs.networkmanager}/bin/nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null \
            | while IFS=: read -r dev type state rest; do
                [[ "$type" == "wifi" || "$type" == "ethernet" ]] || continue
                [[ "$state" == connected* ]] || continue
                printf '%s\n' "$dev"
              done
        }

        nm_connectivity_check() {
          local state

          state="$(${pkgs.networkmanager}/bin/nmcli -t networking connectivity check 2>/dev/null)" \
            || state="unknown"

          [[ -n "$state" ]] || state="unknown"
          printf '%s\n' "''${state,,}"
        }

        set_dns_from_nm() {
          local iface="$1"
          local reason="$2"
          local dns
          local dns_servers=()
          local filtered=()

          # Ask NM for DHCP/static DNS known for this active device.
          mapfile -t dns_servers < <(
            ${pkgs.networkmanager}/bin/nmcli -g IP4.DNS,IP6.DNS device show "$iface" 2>/dev/null
          )

          for dns in "''${dns_servers[@]}"; do
            [[ -n "$dns" ]] && filtered+=("$dns")
          done

          if (( ''${#filtered[@]} > 0 )); then
            log "$reason: using NM/DHCP DNS on $iface: ''${filtered[*]}"
            ${pkgs.systemd}/bin/resolvectl dns "$iface" "''${filtered[@]}"
          else
            # No point clearing DNS here; if NM has no DNS, captive portal DNS cannot be restored.
            log "$reason: no NM/DHCP DNS known for $iface; leaving current DNS unchanged"
          fi
        }

        stop_dnscrypt_service() {
          local reason="$1"
          ${pkgs.systemd}/bin/systemctl is-active --quiet dnscrypt-proxy.service || return 0
          log "stopping dnscrypt-proxy: $reason"
          ${pkgs.systemd}/bin/systemctl stop dnscrypt-proxy.service || true
        }

        dnscrypt_probe() {
          # Query the proxy directly; bypass resolved cache + interface DNS.
          ${pkgs.knot-dns}/bin/kdig +short +timeout=2 +retry=0 \
            @127.0.0.1 example.com >/dev/null 2>&1
        }

        start_dnscrypt_service() {
          ${pkgs.systemd}/bin/systemctl start dnscrypt-proxy.service || return 1
          # Wait for proxy to be ready to answer (up to ~6s).
          local i
          for i in 1 2 3 4 5 6; do
            dnscrypt_probe && return 0
            ${pkgs.coreutils}/bin/sleep 1
          done
          return 1
        }

        set_dnscrypt() {
          local iface="$1"

          if start_dnscrypt_service; then
            log "connectivity=full: dnscrypt healthy, switching $iface to 127.0.0.1"
            ${pkgs.systemd}/bin/resolvectl dns "$iface" 127.0.0.1 ::1
          else
            log "connectivity=full: dnscrypt unhealthy, falling back to DHCP DNS on $iface"
            stop_dnscrypt_service "probe failed after start"
            set_dns_from_nm "$iface" "dnscrypt unhealthy"
          fi
        }

        apply_policy_with_state() {
          local iface="$1"
          local state="$2"
          local conn_id

          is_physical_iface "$iface" || return 0

          conn_id="$(connection_id_for_iface "$iface")"

          if [[ "$conn_id" == "$HOME_SSID" ]]; then
            stop_dnscrypt_service "home network"
            set_dns_from_nm "$iface" "home network"
            return 0
          fi

          if [[ -e "$DISABLE_FILE" ]]; then
            stop_dnscrypt_service "manual override disabled"
            set_dns_from_nm "$iface" "manual override disabled"
            return 0
          fi

          case "$state" in
            full)
              set_dnscrypt "$iface"
              ;;
            *)
              # portal|limited|none|unknown: captive portal etc. need DHCP DNS
              # until auth is complete. Keep dnscrypt-proxy stopped so it does
              # not burn retries against blocked upstream resolvers.
              stop_dnscrypt_service "connectivity=$state"
              set_dns_from_nm "$iface" "connectivity=$state"
              ;;
          esac
        }

        apply_policy_after_device_event() {
          local iface="$1"
          local state

          is_physical_iface "$iface" || return 0

          # Give NM time to push DHCP DNS to resolved/NM state first.
          ${pkgs.coreutils}/bin/sleep 2

          # For non-home networks, restore DHCP DNS before the connectivity check.
          # Otherwise a stale localhost override can break portal detection.
          set_dns_from_nm "$iface" "pre-connectivity-check"

          state="$(nm_connectivity_check)"
          apply_policy_with_state "$iface" "$state"
        }

        case "$2" in
          up|dhcp4-change|dhcp6-change|reapply)
            apply_policy_after_device_event "$1"
            ;;

          connectivity-change)
            # For this action NM does not pass a specific interface.
            # CONNECTIVITY_STATE is uppercase: FULL, PORTAL, LIMITED, NONE, UNKNOWN.
            state="''${CONNECTIVITY_STATE:-UNKNOWN}"
            state="''${state,,}"

            while IFS= read -r iface; do
              apply_policy_with_state "$iface" "$state"
            done < <(connected_physical_ifaces)
            ;;

          *)
            exit 0
            ;;
        esac
      '';
      type = "basic";
    }
  ];
}
