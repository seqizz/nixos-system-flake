{
  config,
  pkgs,
  ...
}: let
  secrets = import ../secrets.nix;
  checkLoadAvg = pkgs.writeScript "check-loadavg" ''
    #! ${pkgs.bash}/bin/bash
    loadavg=$(cat /proc/loadavg | cut -d' ' -f1)
    if (( $(echo "$loadavg > 1.0" | ${pkgs.bc}/bin/bc -l) )); then
      exit 0
    else
      exit 1
      fi
  '';
in {
  systemd.services.notifyload = {
    unitConfig = {
      Description = "Poor man's monitoring";
    };
    serviceConfig = {
      Type = "oneshot";
      ExecCondition = "${checkLoadAvg}";
      ExecStart = "${pkgs.ntfy-sh}/bin/ntfy pub --tags=arrow_upper_right --priority=4 --title='Ayyoooo' --message='Spammers are in hammering ${config.networking.hostName}' ${secrets.ntfyTopic}";
    };
  };

  systemd.timers.notifyload = {
    unitConfig = {
      Description = "Timer for load notifier";
    };
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "10min";
      Persistent = true;
    };
    wantedBy = ["timers.target"];
  };
}
