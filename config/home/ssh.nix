{
  config,
  osConfig,
  pkgs,
  ...
}:
let
  secrets = import ./secrets.nix {
    pkgs = pkgs;
    hostName = osConfig.networking.hostName;
  };
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = secrets.sshSettings;
  };
}
