{ config, pkgs, ...}:
let
  secrets = import ../../secrets.nix;
in
{
  systemd.services.kufur-bot= {
    enable = true;
    wantedBy = [
      "multi-user.target"
    ];
    description = "Kufur bot";
    serviceConfig = {
      ExecStart = let
        python-with-telegram = pkgs.python3.withPackages (ps: with ps; [
          python-telegram-bot
          setuptools
        ]);
      in
        "${python-with-telegram.interpreter} /shared/scripts/kufur-generator/kufur-generator/telegram-kufurbot.py";
      Restart = "always";
      RestartSec = 30;
      StandardOutput = "syslog";
    };
    environment = {
      TELEGRAM_TOKEN = secrets.telegramTokenKufurbot;
    };
  };
}
