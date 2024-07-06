{ config, ... }:
let
  myConfigBase = if config.networking.hostName == "rocksteady" then "/shared" else "/home/gurkan";
  myConfigPath = "${myConfigBase}/syncfolder/dotfiles/nixos-system-flake";
in
{
  environment.shellAliases = {
    tailf = "tail -f";
    vimdiff = "nvim -d";
    # Using this "path:///" nonsense to automate the update because I am NOT including my secret files in the git repo, even encrypted: https://github.com/NixOS/nix/issues/7107#issuecomment-1366095373
    # Waiting for https://github.com/NixOS/nix/pull/9352
    update-flake-inputs = "nix flake update path://${myConfigPath}";
    homeup-noupdate = "home-manager switch --flake path://${myConfigPath}#gurkan@innodellix --option eval-cache false";
    sysup-noupdate = "sudo nixos-rebuild switch --flake path://${myConfigPath}#${config.networking.hostName} --verbose --upgrade --option eval-cache false";
    sysup = "update-flake-inputs && sysup-noupdate && if [[ $(whoami) == 'gurkan' ]]; then echo; echo \"Switching home-manager after waiting 15 sec...\"; sleep 15; homeup-noupdate; fi";
    homeup = "update-flake-inputs && homeup-noupdate";
    sysclean = "if [[ $(whoami) == 'gurkan' ]]; then echo; echo \"Clearing home-manager...\"; home-manager expire-generations \"-10 days\"; fi; sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 14d && sudo nix-collect-garbage -d; sudo nix-store --optimize";
    syslist = "echo 'System:' ; sudo nix-env -p /nix/var/nix/profiles/system --list-generations; if [[ $(whoami) == 'gurkan' ]]; then echo; echo 'Home-manager:'; home-manager generations; fi";
    pkglist = "for pack in `nixos-option environment.systemPackages | head -2 | tail -1 | tr -d \"[],\"`; do echo $pack ; done";
  };
}
