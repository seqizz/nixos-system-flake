{ lib, config, pkgs, inputs,... }:
{
  services.anubis = {
    instances."forgejo".settings = {
      BIND = "/run/anubis/anubis-forgejo/anubis.sock";
      METRICS_BIND = "/run/anubis/anubis-forgejo/anubis-metrics.sock";
      TARGET = "http://${config.services.forgejo.settings.server.HTTP_ADDR}:${toString config.services.forgejo.settings.server.HTTP_PORT}";
    };
  };
  users.users.nginx.extraGroups = [ "anubis" ]; # To access to the socket
}
