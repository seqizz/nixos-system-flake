{
  config,
  pkgs,
  lib,
  ...
}:

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
#     writablePaths = [ "/shared/scripts/my-bot/state" ]; # Optional, everything else is read-only
#   }
#
# All bots run as the shared unprivileged "tgbot" user. The bot scripts must be
# readable by that user but not writable, otherwise a bot compromise could
# rewrite its own code.

let
  hardening = import ./service-hardening.nix;
in
{
  mkTelegramBotService =
    {
      serviceName,
      description,
      scriptPath,
      telegramToken,
      pythonPackages ? [
        "python-telegram-bot"
        "setuptools"
      ],
      additionalEnvVars ? { },
      restartSec ? 30,
      writablePaths ? [ ],
    }:
    {
      users.users.tgbot = {
        isSystemUser = true;
        group = "tgbot";
      };
      users.groups.tgbot = { };

      systemd.services.${serviceName} = {
        enable = true;
        wantedBy = [ "multi-user.target" ];
        description = description;
        serviceConfig = hardening // {
          ExecStart =
            let
              python = pkgs.python3.withPackages (ps: builtins.map (pkg: ps.${pkg}) pythonPackages);
            in
            "${python.interpreter} ${scriptPath}";
          User = "tgbot";
          Group = "tgbot";
          ReadWritePaths = writablePaths;
          Restart = "always";
          RestartSec = restartSec;
          StandardOutput = "syslog";
        };
        environment = {
          TELEGRAM_TOKEN = telegramToken;
          # Script dirs are read-only to the bot, so skip __pycache__ writes
          PYTHONDONTWRITEBYTECODE = "1";
        }
        // additionalEnvVars;
      };
    };
}
