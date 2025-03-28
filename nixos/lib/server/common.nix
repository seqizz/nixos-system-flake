{
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    ../common.nix

    ./acme.nix
    ./bind.nix
    ./bots/anayasa-bot.nix
    ./bots/comar-bot.nix
    ./bots/kufur-bot.nix
    ./bots/timezone-bot.nix
    ./comment-engine.nix
    ./forgejo.nix
    ./gotosocial.nix
    ./logrotate.nix
    ./mailserver.nix
    ./monitor.nix
    ./rustypaste.nix
    ./shadowsocks.nix
    ./ssh.nix
    ./updatesong.nix
    ./websites.nix
    ./yarr.nix
  ];

  environment.systemPackages = with pkgs; [
    zoxide # Not available as an option yet, configured on home-manager separately
  ];

  boot.kernel.sysctl = {
    # I don't have time-critical stuff, but generally low on memory
    "vm.swappiness" = 50;
  };

  services.my_syncthing = {
    repoPath = "/shared/syncfolder";
  };
}
