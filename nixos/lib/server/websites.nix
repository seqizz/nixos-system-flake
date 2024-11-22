{
  config,
  pkgs,
  ...
}: let
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
in {
  networking.firewall.allowedTCPPorts = [80 443];

  environment.systemPackages = with pkgs; [
    regenerateAsNginx
    (pkgs.writeTextFile {
      name = "git-disallow-robots";
      destination = "/var/lib/gitea/custom/public/robots.txt";
      source = ./config_files/gitrobotstxt;
    })
  ];

  services = {
    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      commonHttpConfig = secrets.nginxCommonHttpConfig;
      virtualHosts = secrets.nginxVirtualHostConfig;
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
