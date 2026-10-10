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
    # No `home-manager expire-generations` step: with HM as a NixOS module its
    # packages live in /etc/profiles/per-user and belong to the system closure,
    # so they are freed by the system generation deletion below.
    #
    # The ad-hoc user profile is in nix3 format, so nix-env refuses to touch it
    # ("profile is incompatible with 'nix-env'") and aborts the rest of the
    # chain; it needs `nix profile wipe-history` instead. The system profile is
    # still written by nixos-rebuild via nix-env, so that half stays as it is.
    sysclean = "sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +3 && if [[ -L ~/.local/state/nix/profiles/profile ]]; then nix profile wipe-history --profile ~/.local/state/nix/profiles/profile --older-than 20d; fi && sudo nix-collect-garbage; sudo nix-store --optimize";
    # Userland has no generation list of its own anymore: a HM generation is
    # built into the system generation that activated it. What is still worth
    # printing next to the system list is which specialisation is live (the
    # other thing that changes userland, see work-profile.nix) and whatever was
    # installed imperatively, since that shadows the declarative profile in PATH.
    syslist = "echo 'System:'; sudo nix-env -p /nix/var/nix/profiles/system --list-generations; if [[ -e /etc/nixos-profile ]]; then echo; echo \"Profile: $(cat /etc/nixos-profile)\"; fi; if [[ -L ~/.local/state/nix/profiles/profile ]]; then echo; echo 'Ad-hoc (nix profile):'; nix profile list; fi";
  };
}
