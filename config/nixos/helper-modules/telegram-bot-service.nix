{ config, pkgs, lib, ... }:

# Helper function to create a systemd service for a telegram bot
#
# Usage:
#   mkTelegramBotService {
#     serviceName = "my-bot";
#     description = "My Telegram Bot";
#     scriptPath = "/path/to/bot.py";
#     telegramToken = secrets.telegramTokenMybot;
#     pythonPackages = [ "python-telegram-bot" ]; # Optional, defaults to common packages
#     additionalEnvVars = { FOO = "bar"; };       # Optional, additional environment variables
#   }

{
  mkTelegramBotService = {
    serviceName,
    description,
    scriptPath,
    telegramToken,
    pythonPackages ? [ "python-telegram-bot" "setuptools" ],
    additionalEnvVars ? {},
    restartSec ? 30,
  }: {
    systemd.services.${serviceName} = {
      enable = true;
      wantedBy = [ "multi-user.target" ];
      description = description;
      serviceConfig = {
        ExecStart = let
          python = pkgs.python3.withPackages (ps:
            builtins.map (pkg: ps.${pkg}) pythonPackages
          );
        in
          "${python.interpreter} ${scriptPath}";
        Restart = "always";
        RestartSec = restartSec;
        StandardOutput = "syslog";
      };
      environment = {
        TELEGRAM_TOKEN = telegramToken;
      } // additionalEnvVars;
    };
  };
}
