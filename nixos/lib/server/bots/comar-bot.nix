{ config, pkgs, lib, ...}:
let
  secrets = import ../../secrets.nix;
  helpers = import ../../helper-modules/telegram-bot-service.nix { inherit config pkgs lib; };
in
helpers.mkTelegramBotService {
  serviceName = "comar-bot";
  description = "Comar bot";
  scriptPath = "/shared/scripts/comar-generator/comar-generator/telegram-comarbot.py";
  telegramToken = secrets.telegramTokenComarbot;
}
