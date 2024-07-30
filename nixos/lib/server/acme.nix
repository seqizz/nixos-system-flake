{
  lib,
  config,
  pkgs,
  ...
}: let
  secrets = import ../secrets.nix;
in {
  security.acme = {
    acceptTerms = true;
    defaults.email = secrets.socialMailAddress;
    certs = secrets.acmeCerts;
  };
  systemd.services.dns-rfc2136-conf = {
    requiredBy = ["acme-gurkan.in.service" "acme-siktir.in.service" "bind.service"];
    before = ["acme-gurkan.in.service" "acme-siktir.in.service" "bind.service"];
    unitConfig = {
      ConditionPathExists = "!/shared/bind-zones/secrets/dnskeys.conf";
      RequiresMountsFor = "/shared";
    };
    serviceConfig = {
      Type = "oneshot";
      UMask = 0077;
    };
    path = [pkgs.bind];
    script = ''
      mkdir -p /shared/bind-zones/secrets
      chmod 755 /shared/bind-zones/secrets
      tsig-keygen rfc2136key.siktir.in > /shared/bind-zones/secrets/dnskeys.conf
      chown named:root /shared/bind-zones/secrets/dnskeys.conf
      chmod 400 /shared/bind-zones/secrets/dnskeys.conf

      # extract secret value from the dnskeys.conf
      while read x y; do if [ "$x" = "secret" ]; then secret="''${y:1:''${#y}-3}"; fi; done < /shared/bind-zones/secrets/dnskeys.conf

      cat > /shared/bind-zones/secrets/certs.secret << EOF
      RFC2136_NAMESERVER='127.0.0.1:53'
      RFC2136_TSIG_ALGORITHM='hmac-sha256.'
      RFC2136_TSIG_KEY='rfc2136key.siktir.in'
      RFC2136_TSIG_SECRET='$secret'
      EOF
      chmod 400 /shared/bind-zones/secrets/certs.secret
    '';
  };
}
