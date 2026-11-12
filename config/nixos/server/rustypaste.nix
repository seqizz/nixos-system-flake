{
  config,
  pkgs,
  lib,
  ...
}:
let
  secrets = import ../secrets.nix;
  hardening = import ../helper-modules/service-hardening.nix;
in
{
  users.users.rustypaste = {
    isSystemUser = true;
    # Own group instead of the shared nogroup, so config.toml can be
    # group-readable without exposing it to every other nogroup service
    group = "rustypaste";
  };
  users.groups.rustypaste = { };

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
    # Public upload endpoint, so sandboxed. Only /shared/rustypaste is
    # writable, and within it file ownership decides: config.toml stays
    # root-owned and read-only to the service, only the upload dir is its own.
    serviceConfig = hardening // {
      User = "rustypaste";
      Group = "rustypaste";
      ReadWritePaths = [ "/shared/rustypaste" ];
      MemoryDenyWriteExecute = true;
      ExecStart = "${pkgs.rustypaste}/bin/rustypaste";
      Restart = "always";
      RestartSec = 30;
      StandardOutput = "syslog";
      WorkingDirectory = "/shared/rustypaste";
    };
  };
}
