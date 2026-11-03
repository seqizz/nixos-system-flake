{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  baseconfig = {
    allowUnfree = true;
  };
  lock-helper = (import ./scripts.nix { pkgs = pkgs; }).lock-helper;
  auto-rotate = (import ./scripts.nix { pkgs = pkgs; }).auto-rotate;
  secrets = import ./secrets.nix { pkgs = pkgs; };
  pinentryRofi = pkgs.writeShellApplication {
    name = "pinentry-rofi-with-env";
    text = ''
      PATH="$PATH:${pkgs.coreutils}/bin:${pkgs.rofi}/bin"
      "${pkgs.pinentry-rofi}/bin/pinentry-rofi" "$@"
    '';
  };
  # The cs42l43 codec sometimes loses the race against the SOF controller probe
  # and the sof-soundwire card never gets registered. Unbind/bind of the PCI
  # controller reruns the probe late enough for the codec to be there.
  #
  # needs following fixes, still not on upstream, check later:
  # soundwire: Add a helper function to indicate a device will detach
  # mfd: cs42l43: Move to core detach helper
  rebind-sof = pkgs.writeShellApplication {
    name = "rebind-sof";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
    ];
    text = ''
      if grep -q 'sof-soundwire' /proc/asound/cards; then
        exit 0
      fi

      dev=0000:00:1f.3

      # Nothing bound at all means a different failure mode than the probe
      # race, so do not fail the unit over it.
      if [[ ! -e "/sys/bus/pci/devices/$dev/driver" ]]; then
        echo "no driver bound to $dev, skipping rebind" >&2
        exit 0
      fi

      driver=$(basename "$(readlink "/sys/bus/pci/devices/$dev/driver")")

      echo "$dev" >"/sys/bus/pci/drivers/$driver/unbind"
      sleep 2
      echo "$dev" >"/sys/bus/pci/drivers/$driver/bind"
    '';
  };
in
{
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
      extraOptions = [ "ignore-scrolling" ];
    };

    # https://github.com/nix-community/home-manager/issues/3095
    gpg-agent = {
      enable = true;
      defaultCacheTtl = 86400;
      maxCacheTtl = 86400;
      pinentry.package = pkgs.pinentry-rofi;
      extraConfig = ''
        pinentry-program ${pinentryRofi}/bin/pinentry-rofi-with-env
        auto-expand-secmem
      '';
    };

    xidlehook = {
      package = pkgs.yidlehook;
      enable = true;
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
    startServices = "sd-switch";
    services = {
      updatesong = {
        Unit = {
          Description = "Update last played song on blog";
        };
        Install = {
          WantedBy = [
            "graphical-session.target"
          ];
        };
        Service = {
          ExecStart = "${config.home.profileDirectory}/bin/update-song ${secrets.updateSongSecret}";
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };

      baglan = {
        Unit = {
          Description = "My precious proxy";
        };
        Install = {
          WantedBy = [
            "graphical-session.target"
          ];
        };
        Service = {
          ExecStart = secrets.proxyCommand;
          RestartSec = 10;
          Restart = "always";
        };
      };

      # Some additions for convenience, e.g. if I stopped don't want restart on new generation switch
      xidlehook = lib.mkIf config.services.xidlehook.enable {
        Unit."X-SwitchMethod" = "keep-old";
        Unit.ConditionPathExists = "!%h/.local/state/xidlehook.disabled";
        Service.PrivateTmp = false;
      };

      # Gated on the actual prerequisite: monitor-sensor exits immediately on a
      # box without an IIO accelerometer, and this unit restarts forever.
      auto-rotate = lib.mkIf osConfig.hardware.sensor.iio.enable {
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

      # Only the XPS 14 9440 has the cs42l43 / SOF SoundWire setup, the PCI
      # address is hardcoded for that board.
      rebind-sof = lib.mkIf (osConfig.networking.hostName == "splinter") {
        Unit = {
          Description = "Rebind SOF audio controller when the SoundWire card is missing";
        };
        Install = {
          WantedBy = [
            "graphical-session.target"
          ];
        };
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          # sysfs bind/unbind needs root, wheel is passwordless on the laptops
          ExecStart = "/run/wrappers/bin/sudo -n ${rebind-sof}/bin/rebind-sof";
        };
      };
    };
  };
}
#  vim: set ts=2 sw=2 tw=0 et :
