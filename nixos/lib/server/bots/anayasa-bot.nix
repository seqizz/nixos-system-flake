{ config, pkgs, ...}:
let
  secrets = import ../../secrets.nix;
in
{
  systemd.services.anayasa-bot= {
    enable = true;
    wantedBy = [
      "multi-user.target"
    ];
    description = "Anayasa Bot";
    serviceConfig = {
      ExecStart = let
        python-with-telegram = pkgs.python3.withPackages (ps: with ps; [
          python-telegram-bot
          setuptools
        ]);
      in
        "${python-with-telegram.interpreter} /shared/scripts/anayasaya-noldu/anayasaya-noldu/telegram-anayasabot.py";
      Restart = "always";
      RestartSec = 30;
      StandardOutput = "syslog";
    };
    environment = {
      TELEGRAM_TOKEN = secrets.telegramTokenAnayasabot;
    };
  };
}
