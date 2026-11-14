{ config, ... }:
let
  myConfigBase = if config.local.profiles.server.enable then "/shared" else "/home/gurkan";
  myConfigPath = "${myConfigBase}/syncfolder/dotfiles/nixos-system-flake";
in
{
  environment.shellAliases = {
    tailf = "tail -f";
    vimdiff = "nvim -d";
    update-flake-inputs = "nix flake update --flake ${myConfigPath}";
    sysup-noupdate = "sudo nixos-rebuild switch --flake path://${myConfigPath}#${config.networking.hostName} --verbose --option eval-cache false";
    sysup = "update-flake-inputs && sysup-noupdate";
    syslist = "echo 'System:'; sudo nix-env -p /nix/var/nix/profiles/system --list-generations; if [[ -e /etc/nixos-profile ]]; then echo; echo \"Profile: $(cat /etc/nixos-profile)\"; fi; if [[ -L ~/.local/state/nix/profiles/profile ]]; then echo; echo 'Ad-hoc (nix profile):'; nix profile list; fi";
  };
}
