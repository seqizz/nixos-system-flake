{config, ...}: {
  networking.firewall = {
    allowedTCPPorts = [53];
    allowedUDPPorts = [53];
  };

  services = {
    bind = {
      enable = true;
      # Needed for ACME
      extraConfig = ''
        include "/shared/bind-zones/secrets/dnskeys.conf";
      '';
      zones = [
        {
          name = "gurkan.in";
          master = true;
          slaves = ["none"];
          file = "/shared/bind-zones/gurkan.in.db";
          extraConfig = "allow-update { key rfc2136key.siktir.in.; };";
        }
        {
          name = "siktir.in";
          master = true;
          slaves = ["none"];
          file = "/shared/bind-zones/siktir.in.db";
          extraConfig = "allow-update { key rfc2136key.siktir.in.; };";
        }
      ];
    };
  };
}
