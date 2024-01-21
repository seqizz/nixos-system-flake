{ config, ... }:
{
  environment.shellAliases = {
    tailf = "tail -f";
    vimdiff = "nvim -d";
    # non-flake (it was so easier..)
    # sysup = "sudo nixos-rebuild switch --upgrade && if [[ $(whoami) == 'gurkan' ]]; then echo; echo \"Switching home-manager after waiting 15 sec...\"; sleep 15; nix-env -u && home-manager switch -b FUCK; fi";
    # Using this trick to automate the update because I am not including my secret files: https://github.com/NixOS/nix/issues/7107#issuecomment-1366095373
    # This is nonsense.. Waiting for https://github.com/NixOS/nix/pull/9352
    sysup = "sudo nixos-rebuild switch --flake path:///home/gurkan/syncfolder/dotfiles/nixos-system-flake#innodellix --verbose --upgrade && if [[ $(whoami) == 'gurkan' ]]; then echo; echo \"Switching home-manager after waiting 15 sec...\"; sleep 15; nix-env -u && home-manager switch --flake path:///home/gurkan/syncfolder/dotfiles/nixos-system-flake#gurkan@innodellix ; fi";
    sysclean = "if [[ $(whoami) == 'gurkan' ]]; then echo; echo \"Clearing home-manager...\"; home-manager expire-generations \"-10 days\"; fi; sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +10 && sudo nix-collect-garbage -d; sudo nix-store --optimize";
    syslist = "echo 'System:' ; sudo nix-env -p /nix/var/nix/profiles/system --list-generations; if [[ $(whoami) == 'gurkan' ]]; then echo; echo 'Home-manager:'; home-manager generations; fi";
    pkglist = "for pack in `nixos-option environment.systemPackages | head -2 | tail -1 | tr -d \"[],\"`; do echo $pack ; done";
  };
}
