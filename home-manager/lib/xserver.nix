{config, pkgs, ...}:

let
  # baseconfig = { allowUnfree = true; };
  # unstable = import (
    # fetchTarball https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz
  # ) { config = baseconfig; };
  # @Reference from autorandr times, might be useful later
  # get_dpi_commands = list: [
    # "${pkgs.xorg.xrandr}/bin/xrandr --dpi ${toString list.dpi}"
    # "echo 'Xft.dpi: ${toString list.dpi}' | ${pkgs.xorg.xrdb}/bin/xrdb -merge"
  # ];
in
{

  home.keyboard.layout = "tr";

  systemd.user.services.loose = {
    Unit = {
      Description = "Loose🫠 the Xrandr smasher";
    };
    Install = {
      WantedBy = [
        "multi-user.target"
        "graphical-session.target"
      ];
    };
    Service = {
      ExecStart = "${pkgs.loose}/bin/loose rotate -e";
      Type = "oneshot";
      RemainAfterExit = true;
      # We'd like to be able to run anything available on system via hooks
      Environment = "PATH=$PATH:/run/current-system/sw/bin";
    };
  };

  gtk = {
    enable = true;
    font = {
      name = "Noto Sans";
      size = 10;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 0;
      gtk-button-images = 1;
      gtk-icon-theme-name = "Papirus";
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
    style.name = "Fusion";
  };

  xsession = {
    enable = true;
    numlock.enable = true;

    scriptPath = ".hm-xsession";
    # ${pkgs.dbus}/bin/dbus-run-session ${pkgs.awesome}/bin/awesome
    windowManager.command = ''
    ${pkgs.dbus}/bin/dbus-run-session ${pkgs.awesome}/bin/awesome
    '';
    initExtra = ''
      # Trigger loose with reset switch
      ${pkgs.loose}/bin/loose rotate -r
    '';
  };

  home.pointerCursor = {
    x11.enable = true;
    package = pkgs.capitaine-cursors;
    name = "capitaine-cursors";
    size = 32;
  };

}
