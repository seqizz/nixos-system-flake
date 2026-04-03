{ config, pkgs, lib, ...}:
let
  secrets = import ../../secrets.nix;
  helpers = import ../../helper-modules/telegram-bot-service.nix { inherit config pkgs lib; };
in
helpers.mkTelegramBotService {
  serviceName = "anayasa-bot";
  description = "Anayasa Bot";
  scriptPath = "/shared/scripts/anayasaya-noldu/anayasaya-noldu/telegram-anayasabot.py";
  telegramToken = secrets.telegramTokenAnayasabot;
}
