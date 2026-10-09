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
    # Follows the specialisation, so a work-mode switch rewrites ~/.ssh/config
    # along with everything else.
    work = config.local.profiles.work.enable;
  };
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = secrets.sshSettings;
  };
}
