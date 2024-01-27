{ config, ... }:
{
  environment.shellAliases = {
    tailf = "tail -f";
    vimdiff = "nvim -d";
    # Using this "path:///" nonsense to automate the update because I am NOT including my secret files in the git repo, even encrypted: https://github.com/NixOS/nix/issues/7107#issuecomment-1366095373
    # Waiting for https://github.com/NixOS/nix/pull/9352
    update-flake-inputs = "nix flake update path:///home/gurkan/syncfolder/dotfiles/nixos-system-flake";
    sysup-noupdate = "sudo nixos-rebuild switch --flake path:///home/gurkan/syncfolder/dotfiles/nixos-system-flake#innodellix --verbose --upgrade && if [[ $(whoami) == 'gurkan' ]]; then echo; echo \"Switching home-manager after waiting 15 sec...\"; sleep 15; nix-env -u && home-manager switch --flake path:///home/gurkan/syncfolder/dotfiles/nixos-system-flake#gurkan@innodellix ; fi";
    sysup = "update-flake-inputs && sysup-noupdate";
    homeup = "update-flake-inputs && nix-env -u && home-manager switch --flake path:///home/gurkan/syncfolder/dotfiles/nixos-system-flake#gurkan@innodellix";
    sysclean = "if [[ $(whoami) == 'gurkan' ]]; then echo; echo \"Clearing home-manager...\"; home-manager expire-generations \"-10 days\"; fi; sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +10 && sudo nix-collect-garbage -d; sudo nix-store --optimize";
    syslist = "echo 'System:' ; sudo nix-env -p /nix/var/nix/profiles/system --list-generations; if [[ $(whoami) == 'gurkan' ]]; then echo; echo 'Home-manager:'; home-manager generations; fi";
    pkglist = "for pack in `nixos-option environment.systemPackages | head -2 | tail -1 | tr -d \"[],\"`; do echo $pack ; done";
  };
}
