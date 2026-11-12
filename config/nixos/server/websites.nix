{
  config,
  lib,
  pkgs,
  ...
}:
let
  secrets = import ../secrets.nix;
  regenerateAsNginx = pkgs.writeScriptBin "regenerateAsNginx" ''
    #!/usr/bin/env sh
    if [ -z $1 ]; then
      echo "Give me a hostname"
      exit 1
    fi

    mkdir -p /tmp/hugo_cache
    chown -R nginx:nginx /tmp/hugo_cache

    cd /shared/vhosts/$1
    if [ "$1" == "siktir.in" ]; then
      su -s /run/current-system/sw/bin/zsh -c ${pkgs.hugo-56}/bin/hugo-56 nginx
    else
      su -s /run/current-system/sw/bin/zsh -c ${pkgs.hugo}/bin/hugo nginx
    fi
  '';
in
{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  environment = {
    systemPackages = with pkgs; [
      regenerateAsNginx
    ];
    etc = {
      # Not sure why I am doing this
      "nginx/.updateSongSecret".text = secrets.updateSongSecret;
      # Autoindex XSLT for the browsable media dirs. Lives under /etc because
      # the vhosts come out of secrets.nix, which is a plain attrset with no
      # access to pkgs and therefore cannot reference a store path.
      "nginx/gallery-index.xslt".source = ./gallery-index.xslt;
      # Later
      # "fail2ban/filter.d/nginx-probing.conf".text = ''
      # [Definition]
      # failregex = ^<HOST>.*GET.*/\.env HTTP/\d.\d\" 404.*$
      # ^<HOST>.*GET.*/\.env HTTP/\d.\d\" 404.*$
      # '';
    };
  };

  # The browsable media dirs are written by syncthing and read by nginx. Setgid
  # makes everything syncthing drops in there land in the nginx group rather
  # than inheriting syncthing's, so nginx keeps group read without the tree
  # having to be world readable.
  #
  # tmpfiles rather than an activation script: activation only runs on
  # nixos-rebuild switch, so a plain reboot would never reapply it.
  #
  # The paths live in secrets.nix (`galleryDirs`, a list of absolute paths) so
  # the layout of the sync tree stays out of the public repo.
  systemd.tmpfiles.settings."10-nginx-gallery" = lib.genAttrs secrets.galleryDirs (_: {
    d = {
      user = "syncthing";
      group = "nginx";
      # Setgid, but no group write: nginx only ever reads here.
      mode = "2755";
    };
  });

  services = {
    geoipupdate = {
      enable = true;
      settings = {
        EditionIDs = [
          "GeoLite2-ASN"
          "GeoLite2-City"
          "GeoLite2-Country"
        ];
        AccountID = secrets.maxmindUserID;
        LicenseKey = {
          _secret = "/shared/.maxmind_key";
        };
        DatabaseDirectory = "/var/lib/GeoIP";
      };
    };
    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      commonHttpConfig = secrets.nginxCommonHttpConfig;
      # Without a charset in Content-Type, browsers fall back to Windows-1252
      # and mangle UTF-8 in text/plain (e.g. forgejo's robots.txt banner).
      # Only labels charset_types responses that lack one, nothing is recoded.
      appendHttpConfig = ''
        charset utf-8;
      '';
      virtualHosts = secrets.nginxVirtualHostConfig;
      additionalModules = with pkgs.nginxModules; [
        geoip2
      ];
    };
    # @Reference, I don't do that shit anymore
    # mysql = {
    #   enable = true;
    #   package = pkgs.mariadb;
    #   dataDir = "/shared/databases/mysql";
    #   settings = {
    #     mysqld = {
    #       performance_schema = "off";
    #     };
    #   };
    # };
    # phpfpm.pools."www" = {
    #   user = "nginx";
    #   settings = {
    #     "listen.group" = "nginx";
    #     "listen.mode" = "0600";
    #     "listen.owner" = "nginx";
    #     "pm" = "dynamic";
    #     "pm.max_children" = 5;
    #     "pm.max_requests" = 500;
    #     "pm.max_spare_servers" = 3;
    #     "pm.min_spare_servers" = 1;
    #     "pm.start_servers" = 2;
    #   };
    # };
  };
  # systemd.services.mysql.restartIfChanged = false;
}
