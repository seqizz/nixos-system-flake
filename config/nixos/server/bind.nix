{ config, ... }: {
  networking.firewall = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
  };

  services = {
    bind = {
      enable = true;
      # Since I am using config files not in nix store, this disables build-time check
      checkConfig = false;
      # Public authoritative server: response rate limiting stops it being
      # used as a DNS amplification reflector. Limits are per client /24
      # (/56 on v6) per identical answer, so real resolvers never get near
      # them. slip 2 answers every 2nd dropped query with TC=1, so a spoofed
      # victim's legit resolver can still retry over TCP.
      extraOptions = ''
        rate-limit {
          responses-per-second 20;
          window 5;
          slip 2;
          exempt-clients { 127.0.0.0/8; ::1; };
        };
      '';
      # Needed for ACME
      extraConfig = ''
        include "/shared/bind-zones/secrets/dnskeys.conf";
      '';
      zones = [
        {
          name = "gurkan.in";
          master = true;
          slaves = [ "none" ];
          file = "/shared/bind-zones/gurkan.in.db";
          extraConfig = "allow-update { key rfc2136key.siktir.in.; };";
        }
        {
          name = "siktir.in";
          master = true;
          slaves = [ "none" ];
          file = "/shared/bind-zones/siktir.in.db";
          extraConfig = "allow-update { key rfc2136key.siktir.in.; };";
        }
      ];
    };
  };
}
