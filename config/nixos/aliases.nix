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
    # Waiting for https://github.com/NixOS/nix/pull/9352 (p.s. it will never happen)
    # update-flake-inputs = "nix flake update path://${myConfigPath}";
    # Instead, I am using lix which does it differently:
    update-flake-inputs = "nix flake update --flake ${myConfigPath}";
    # Home Manager is a NixOS module now (config/nixos/home-manager.nix), so
    # userland is switched by nixos-rebuild together with the system. There is
    # no `home-manager switch` target to call anymore.
    sysup-noupdate = "sudo nixos-rebuild switch --flake path://${myConfigPath}#${config.networking.hostName} --verbose --option eval-cache false";
    sysup = "update-flake-inputs && sysup-noupdate";
    # The user profile is in nix3 format, so nix-env refuses to touch it ("profile
    # is incompatible with 'nix-env'") and aborts the rest of the chain. The
    # system profile is still written by nixos-rebuild via nix-env, so that half
    # stays as it is.
    sysclean = "if [[ $(whoami) == 'gurkan' ]]; then echo \"Clearing home-manager...\"; home-manager expire-generations \"-20 days\"; fi; sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +3 && if [[ -L ~/.local/state/nix/profiles/profile ]]; then nix profile wipe-history --profile ~/.local/state/nix/profiles/profile --older-than 20d; fi && sudo nix-collect-garbage; sudo nix-store --optimize";
    syslist = "echo 'System:' ; sudo nix-env -p /nix/var/nix/profiles/system --list-generations; if [[ $(whoami) == 'gurkan' ]]; then echo; echo 'Home-manager:'; home-manager generations; fi";
  };
}
