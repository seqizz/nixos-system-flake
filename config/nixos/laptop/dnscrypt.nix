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
# - The policy itself lives in config/home/config_files/dnsmagic-lib.sh, installed
#   to /etc/dnsmagic by grafts/nixos/dnsmagic.nix. The dispatcher below and the
#   dnsmagic-pause/-resume/-check wrappers are thin front-ends over it.
# - Every resolver switch flushes resolved's cache. That cache is global rather
#   than per-link, so without the flush a name only the home pi-hole knows stays
#   NXDOMAIN for the full negative TTL after arriving home, and names blocked by
#   gravity stay unblocked after leaving.
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
    settings.Resolve = {
      FallbackDNS = [ "9.9.9.9" ];
      # avahi owns mDNS (nssmdns + printer/samba discovery). Two mDNS stacks
      # joining the same multicast group makes discovery unreliable, so keep
      # resolved out of it. LLMNR left on (avahi doesn't handle it).
      MulticastDNS = false;
    };
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
      # Use TCP to upstream resolvers. resolved fires A+AAAA in parallel; over
      # UDP the internet path occasionally drops one query, and dnscrypt then
      # sits on its (default 5000ms) timeout with no fast per-query retry, so a
      # single lost packet costs a full 5s cold lookup. TCP retransmits lost
      # segments itself, removing those stalls.
      force_tcp = true;
      cache = true;
      cache_size = 512;
      cache_min_ttl = 60;
      cache_max_ttl = 720;
    };
  };

  # The dispatcher is a thin wrapper: all policy lives in the shared library at
  # /etc/dnsmagic (grafts/nixos/dnsmagic.nix), so the dnsmagic-pause/-resume
  # wrappers and this script cannot drift apart.
  environment.etc."dnsmagic/home-ssid" = {
    text = secrets.homeSSID + "\n";
    mode = "0400";
  };

  networking.networkmanager.dispatcherScripts = [
    {
      source = pkgs.writeText "dnscrypt-override" ''
        #!/usr/bin/env ${pkgs.bash}/bin/bash

        set -uo pipefail

        # Commands with paths (for NM dispatcher context)
        nmcli="${pkgs.networkmanager}/bin/nmcli"
        resolvectl="${pkgs.systemd}/bin/resolvectl"
        systemctl="${pkgs.systemd}/bin/systemctl"
        logger="${pkgs.util-linux}/bin/logger"
        kdig="${pkgs.knot-dns}/bin/kdig"
        sleep="${pkgs.coreutils}/bin/sleep"

        source /etc/dnsmagic/dnsmagic-lib.sh

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
              apply_policy "$iface" auto "$state"
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
