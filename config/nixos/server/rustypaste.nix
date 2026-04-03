{ config, pkgs, lib, ...}:
let
  secrets = import ../secrets.nix;
in
{
  users.users.rustypaste = {
    isSystemUser = true;
    group = "nogroup";
  };

  # Systemd definitions
  systemd.services.rustypaste = {
    enable = true;
    wantedBy = [
      "multi-user.target"
    ];
    description = "Paste service";
    environment = {
      AUTH_TOKEN = secrets.rustypasteToken;
      CONFIG = "/shared/rustypaste/config.toml";
    };
    serviceConfig = {
      User = "rustypaste";
      ExecStart = "${pkgs.unstable.rustypaste}/bin/rustypaste";
      Restart = "always";
      RestartSec = 30;
      StandardOutput = "syslog";
      WorkingDirectory = "/shared/rustypaste";
    };
  };
}
