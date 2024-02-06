{ config, pkgs, ...}:
let
  secrets = import ../../secrets.nix;
in
{
  systemd.services.comar-bot = {
    enable = true;
    wantedBy = [
      "multi-user.target"
    ];
    description = "Comar bot";
    serviceConfig = {
      ExecStart = let
        python-with-telegram = pkgs.python3.withPackages (ps: with ps; [
          python-telegram-bot
          setuptools
        ]);
      in
        "${python-with-telegram.interpreter} /shared/scripts/comar-generator/comar-generator/telegram-comarbot.py";
      Restart = "always";
      RestartSec = 30;
      StandardOutput = "syslog";
    };
    environment = {
      TELEGRAM_TOKEN = secrets.telegramTokenComarbot;
    };
  };
}
