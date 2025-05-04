{ lib, config, pkgs, inputs,... }:
{
  services.anubis = {
    instances."forgejo".settings = {
      TARGET = "http://${config.services.forgejo.settings.server.HTTP_ADDR}:${toString config.services.forgejo.settings.server.HTTP_PORT}";
    };
  };
  users.users.nginx.extraGroups = [ "anubis" ]; # To access to the socket
}
