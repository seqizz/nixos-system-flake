{ config, pkgs, lib, ...}:
let
  secrets = import ../../secrets.nix;
  helpers = import ../../helper-modules/telegram-bot-service.nix { inherit config pkgs lib; };
in
helpers.mkTelegramBotService {
  serviceName = "kufur-bot";
  description = "Kufur bot";
  scriptPath = "/shared/scripts/kufur-generator/kufur-generator/telegram-kufurbot.py";
  telegramToken = secrets.telegramTokenKufurbot;
}
