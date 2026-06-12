{config, pkgs, ...}:
let
  secrets = import ./secrets.nix {pkgs=pkgs;};
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = secrets.sshSettings;
  };
}
