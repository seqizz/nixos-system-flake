{
  config,
  pkgs,
  lib,
  ...
}: let
  secrets = import ../../secrets.nix;
  helpers = import ../../helper-modules/telegram-bot-service.nix {inherit config pkgs lib;};
in
  helpers.mkTelegramBotService {
    serviceName = "bllk-timezone-bot";
    description = "Timezone bot";
    scriptPath = "/shared/scripts/bllk_timezone_v4.py";
    telegramToken = secrets.telegramTokenTimezonebot;
    additionalEnvVars = {OWM_TOKEN = secrets.owmToken;};
    pythonPackages = ["python-telegram-bot" "pytz" "pyowm" "setuptools"];
  }
