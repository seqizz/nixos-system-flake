{
  config,
  lib,
  pkgs,
  ...
}: let
  secrets = import ./secrets.nix;
in
  # Common options for all of my machines
  {
    imports = [
      # ./overlays.nix
      ./aliases.nix
      ./gitconfig.nix
      ./neovim.nix
      ./packages.nix
      ./scripts.nix
      ./sheldon.nix
      ./syncthing.nix
      ./users.nix
      ./variables.nix
    ];

    # When there is a false positive
    # nixpkgs.config.allowBroken = true;

    i18n = {
      defaultLocale = "en_DK.UTF-8";
    };

    time.timeZone = "Europe/Berlin";

    boot = {
      tmp = {
        useTmpfs = false;
        cleanOnBoot = true;
      };
      kernel.sysctl = {
        "kernel.pty.max" = 24000;
        "kernel.sysrq" = 1;
        "kernel.dmesg_restrict" = 0;
      };
    };

    services = {
      envfs.enable = true;
      journald.extraConfig = ''
        SystemMaxUse=1G
      '';
    };

    nix = {
      settings = {
        allowed-users = ["@wheel"];
        # add binary caches
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
        substituters = [
          "https://cache.nixos.org"
          "https://nix-community.cachix.org"
        ];
      };
      package = pkgs.lix;
      extraOptions = ''
        keep-outputs = true
        keep-derivations = true
        experimental-features = nix-command flakes
        access-tokens = github.com=${secrets.githubRateLimitAccessToken}
        trusted-users = root gurkan
      '';
    };
  }
#  vim: set ts=2 sw=2 tw=0 et :

