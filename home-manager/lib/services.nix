{
  config,
  lib,
  pkgs,
  ...
}: let
  baseconfig = {allowUnfree = true;};
  # In case I want to use the packages I need on other channels
  unstable = import (
    fetchTarball https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz
  ) {config = baseconfig;};
  lock-helper = (import ./scripts.nix {pkgs = pkgs;}).lock-helper;
  auto-rotate = (import ./scripts.nix {pkgs = pkgs;}).auto-rotate;
  secrets = import ./secrets.nix {pkgs = pkgs;};
  pinentryRofi = pkgs.writeShellApplication {
    name = "pinentry-rofi-with-env";
    text = ''
      PATH="$PATH:${pkgs.coreutils}/bin:${pkgs.rofi}/bin"
      "${pkgs.pinentry-rofi}/bin/pinentry-rofi" "$@"
    '';
  };
in {
  services = {
    kdeconnect.enable = true;
    playerctld.enable = true;
    udiskie.enable = true;
    network-manager-applet.enable = true;

    redshift = {
      enable = true;
      latitude = "53.551086";
      longitude = "9.993682";
    };

    unclutter = {
      enable = true;
      threshold = 15;
      timeout = 2;
      extraOptions = ["ignore-scrolling"];
    };

    # https://github.com/nix-community/home-manager/issues/3095
    gpg-agent = {
      enable = true;
      defaultCacheTtl = 86400;
      maxCacheTtl = 86400;
      pinentryFlavor = null;
      extraConfig = ''
        pinentry-program ${pinentryRofi}/bin/pinentry-rofi-with-env
        auto-expand-secmem
      '';
    };

    xidlehook = {
      enable = true;
      # @Reference: Overriding rust stuff via cargoDeps
      # Seems like original author has passed away, RIP @jD91mZM2
      package = pkgs.xidlehook.overrideAttrs (out: rec {
        version = "unstable-2022-05-18";
        src = pkgs.fetchFromGitHub {
          owner = "realSaltyFish";
          repo = "xidlehook";
          rev = "12ea7a8d074fa5907f757e9df85f35c44252e13d";
          sha256 = "12f7yfwjijcy5cwj60ba7h8lpgxq25kgf0infyzkrivyzsyk6nrz";
        };
        cargoDeps = out.cargoDeps.overrideAttrs (_: {
          inherit src; # You need to pass "src" here again
          outputHash = "sha256-Iuri3dOLzrfTzHvwOKcZrVJFotqrGlM6EeuV29yqz+U=";
        });
      });
      not-when-fullscreen = true;
      environment = {
        "DISPLAY" = ":0";
      };
      timers = [
        {
          delay = 250;
          command = "${lock-helper}/bin/lock-helper start";
          canceller = "${lock-helper}/bin/lock-helper cancel";
        }
        {
          delay = 120;
          command = "${lock-helper}/bin/lock-helper lock";
          canceller = "${lock-helper}/bin/lock-helper cancel";
        }
      ];
    };
  };

  systemd.user = {
    startServices = true;
    services = {
      baglan = {
        Unit = {
          Description = "My precious proxy";
        };
        Install = {
          WantedBy = [
            "multi-user.target"
            "graphical-session.target"
          ];
        };
        Service = {
          ExecStart = secrets.proxyCommand;
          RestartSec = 10;
          Restart = "always";
        };
      };

      # An addition to make my xidlehook wrapper work
      xidlehook = lib.mkIf config.services.xidlehook.enable {
        Service.PrivateTmp = false;
      };

      auto-rotate = {
        Unit = {
          Description = "Automatic screen rotation helper";
          After = [
            "graphical-session.target"
          ];
        };
        Service = {
          ExecStart = "${pkgs.bash}/bin/bash ${auto-rotate}/bin/auto-rotate";
          ExecStop = "${pkgs.psmisc}/bin/killall monitor-sensor";
          RestartSec = 5;
          Restart = "always";
          Environment = "DISPLAY=:0";
          PrivateTmp = "false";
        };
      };
    };
  };
}
#  vim: set ts=2 sw=2 tw=0 et :
