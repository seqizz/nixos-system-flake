{
  config,
  pkgs,
  ...
}: let
  my_scripts = import ./scripts.nix {pkgs = pkgs;};
in {
  systemd.user.services.tarsnap-dotfiles = {
    Unit = {
      Description = "Run tarsnap-dotfiles";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${my_scripts.tarsnap-dotfiles}/bin/tarsnap-dotfiles";
      Restart = "on-failure";
      RestartSec = "1h";
      StartLimitInterval = "1week";
      StartLimitBurst = "5";
    };
  };

  systemd.user.timers.tarsnap-dotfiles = {
    Unit = {
      Description = "Timer for tarsnap-dotfiles";
    };
    Timer = {
      OnCalendar = "*-01,04,07,10-01 00:00:00";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
    Install = {
      WantedBy = ["timers.target"];
    };
  };
}
