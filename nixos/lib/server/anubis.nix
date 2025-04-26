# { lib, config, pkgs, inputs,... }:
{
  lib,
  config,
  ...
}: {
  # imports = [
  # "${inputs.nixpkgs-unstable}/nixos/modules/services/networking/anubis.nix"
  # ];
  services.anubis = {
    # package = pkgs.unstable.anubis;
    instances."forgejo".settings = {
      TARGET = "http://${config.services.forgejo.settings.server.HTTP_ADDR}:${toString config.services.forgejo.settings.server.HTTP_PORT}";
    };
  };
  users.users.nginx.extraGroups = ["anubis"]; # To access to the socket
}
