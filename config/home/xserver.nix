{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Kvantum is an SVG-driven Qt style engine; unlike Fusion it gives rounded
  # widgets and soft contrast without needing a KDE session.
  kvantumTheme = "KvGnomeDark";

  # "-dark" suffix selects the dark variant of the configured Kvantum theme.
  # Home Manager exports this as QT_STYLE_OVERRIDE, so it must match the value
  # written into the qt5ct/qt6ct configs or the env var wins over them.
  kvantumStyle = "kvantum-dark";

  qtctSettings = {
    Appearance = {
      style = kvantumStyle;
      icon_theme = "Papirus-Dark";

      # Palette comes from the Kvantum theme SVG, a custom_palette would win over it
      custom_palette = false;
    };
    Fonts = {
      general = ''"Noto Sans,10,-1,5,50,0,0,0,0,0"'';
      fixed = ''"Noto Sans Mono,10,-1,5,50,0,0,0,0,0"'';
    };
  };
in
{
  home.keyboard.layout = "tr";

  systemd.user.services.loose = {
    Unit = {
      Description = "Loose🫠 the Xrandr smasher";
      After = [
        "sleep.target"
        "systemd-suspend.service"
        "systemd-hibernate.service"
      ];
    };
    Service = {
      # Wait for X to be ready (NVIDIA©, amazing)
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 3";
      ExecStart = "${pkgs.loose}/bin/loose rotate -e -v";
      Type = "oneshot";
      RemainAfterExit = true;
      # We'd like to be able to run anything available on system via hooks
      Environment = "PATH=$PATH:/run/current-system/sw/bin";
    };
  };

  systemd.user.services.libinput-gestures = {
    Unit = {
      Description = "Libinput Gestures";
    };
    Install = {
      WantedBy = [
        "multi-user.target"
        "graphical-session.target"
      ];
    };
    Service = {
      ExecStart = "${pkgs.libinput-gestures}/bin/libinput-gestures";
    };
  };

  systemd.user.services.touchegg-client = {
    Unit = {
      Description = "Touchegg client for touchscreen gestures";
      After = [ "graphical-session.target" ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.touchegg}/bin/touchegg --client";
      Restart = "on-failure";
      RestartSec = 3;
    };
  };

  gtk = {
    enable = true;
    font = {
      name = "Noto Sans";
      size = 10;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-button-images = 1;
      gtk-icon-theme-name = "Papirus-Dark";
      gtk-menu-images = 1;
      gtk-enable-event-sounds = 0;
      gtk-enable-input-feedback-sounds = 0;
      gtk-xft-antialias = 1;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "hintslight";
      gtk-xft-rgba = "rgb";
    };
  };

  qt = {
    enable = true;
    # Sets QT_QPA_PLATFORMTHEME=qt5ct, which serves Qt6 too: the qt6ct plugin
    # registers both the "qt5ct" and "qt6ct" platform theme keys
    platformTheme.name = "qtct";
    style.name = kvantumStyle;
    qt5ctSettings = qtctSettings;
    qt6ctSettings = qtctSettings;
  };

  xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
    [General]
    theme=${kvantumTheme}
  '';

  xsession = {
    enable = true;
    numlock.enable = true;

    scriptPath = ".hm-xsession";
    # ${pkgs.dbus}/bin/dbus-run-session ${pkgs.awesome}/bin/awesome
    windowManager.command = ''
      ${pkgs.systemd}/bin/systemctl --user import-environment DISPLAY XAUTHORITY
      ${pkgs.dbus}/bin/dbus-update-activation-environment --all --systemd --verbose
      ${pkgs.awesome}/bin/awesome
    '';
    initExtra = ''
      # Trigger loose with reset switch
      ${pkgs.loose}/bin/loose rotate -r -i -v > ~/.Xlog-initial-loose.log 2>&1
      # Disable DPMS by default
      ${pkgs.xorg.xset}/bin/xset -dpms
      # Disable screensaver by default
      ${pkgs.xorg.xset}/bin/xset s off
    '';
  };

  home.pointerCursor = {
    x11.enable = true;
    package = pkgs.capitaine-cursors;
    name = "capitaine-cursors";
    size = 32;
  };

  home.packages = with pkgs; [
    (pkgs.writeScriptBin "get-ddc-current-brightness" ''
      sudo ddcutil --brief getvcp 10 | awk '{print $4}'
    '')
    (pkgs.writeScriptBin "get-ddc-max-brightness" ''
      sudo ddcutil --brief getvcp 10 | awk '{print $5}'
    '')
    papirus-icon-theme
    libsForQt5.qt5ct
    qt6Packages.qt6ct
    # Style plugin needed once per Qt major version, otherwise apps of that
    # version silently fall back to Fusion
    libsForQt5.qtstyleplugin-kvantum
    kdePackages.qtstyleplugin-kvantum # also provides the kvantummanager GUI
  ];
}
