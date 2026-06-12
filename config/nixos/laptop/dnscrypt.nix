# DNS resolution strategy (in order of preference):
#
# 1. VPN routing domains (highest priority)
#    WireGuard connections push per-link DNS with routing domains if available
#    systemd-resolved routes matching domains' queries to VPN DNS, regardless of other settings.
#    Configured in: wgconfig-inno.nix (via nm-wg-config.nix dnsSearchAddress)
#
# 2. Home wifi (SSID match)
#    When connected to home SSID, DHCP provides pi-hole as per-link DNS.
#    Dispatcher does nothing, resolved uses DHCP DNS naturally.
#
# 3. Outside networks (no SSID match)
#    NM dispatcher overrides per-link DNS to 127.0.0.1 (dnscrypt-proxy).
#    All queries go through encrypted DNS, can't trust them.
#
# 4. Fallback (last resort)
#    If dnscrypt is down and no per-link DNS available, resolved falls back to 9.9.9.9.
#
# Key details:
# - dnscrypt-proxy always runs, but only receives queries when outside home
# - networking.nameservers forced empty to prevent dnscrypt module from setting global DNS
# - NM dispatcher uses sleep 2 to avoid race with NM's own DNS push to resolved

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

  # Don't let dnscrypt-proxy module set global DNS, we manage per-link DNS via dispatcher
  networking.nameservers = lib.mkForce [ ];

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

  # When not on home wifi, override per-link DNS to use dnscrypt
  networking.networkmanager.dispatcherScripts = [
    {
      source = pkgs.writeText "dnscrypt-override" ''
        #!/usr/bin/env ${pkgs.bash}/bin/bash

        HOME_SSID="${secrets.homeSSID}"

        # Only act on physical interface up events (skip VPN, bridges, loopback)
        [[ "$2" != "up" ]] && exit 0
        [[ "$1" == IG-WG-* ]] && exit 0
        [[ "$1" == lo ]] && exit 0
        [[ "$1" != wlp* && "$1" != enp* ]] && exit 0

        CURRENT_SSID="$CONNECTION_ID"

        if [[ "$CURRENT_SSID" != "$HOME_SSID" ]]; then
          # Brief delay to ensure NM has finished pushing DNS to resolved
          sleep 2
          logger "dnscrypt-override: not home, setting DNS to dnscrypt for $1"
          ${pkgs.systemd}/bin/resolvectl dns "$1" 127.0.0.1
        else
          logger "dnscrypt-override: home network, using DHCP DNS for $1"
        fi
      '';
      type = "basic";
    }
  ];
}
