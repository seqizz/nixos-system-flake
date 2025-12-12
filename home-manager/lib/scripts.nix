{pkgs, ... }:
let
  writeSubbedBin = (import ../../nixos/lib/helper-modules/writeSubbedBin.nix {
    pkgs = pkgs;
  }).writeSubbedBin;

  awk = pkgs.gawk;
  awesome = pkgs.awesome;
  bash = pkgs.bash;
  brightnessctl = pkgs.brightnessctl;
  coreutils = pkgs.coreutils;
  grep = pkgs.gnugrep;
  iiosensorproxy = pkgs.iio-sensor-proxy;
  inotifytools = pkgs.inotify-tools;
  libnotify = pkgs.libnotify;
  procps = pkgs.procps;
  sed = pkgs.gnused;
  slock = pkgs.slock;
  xinput = pkgs.xorg.xinput;
  xrandr = pkgs.xorg.xrandr;
  xclip = pkgs.xclip;
  xset = pkgs.xorg.xset;
in
{
  auto-rotate = (writeSubbedBin {
    name = "auto-rotate";
    src = ./scripts/auto-rotate;
    inherit bash grep sed xinput xrandr coreutils iiosensorproxy inotifytools awk;
  });
  workman-toggle = (writeSubbedBin {
    name = "workman-toggle";
    src = ./scripts/workman-toggle;
    inherit bash;
  });
  bulb-toggle = (writeSubbedBin {
    name = "bulb-toggle";
    src = ./scripts/bulb-toggle;
  });
  update-song = (writeSubbedBin {
    name = "update-song";
    src = ./scripts/update-song;
  });
  innovpn-toggle = (writeSubbedBin {
    name = "innovpn-toggle";
    src = ./scripts/innovpn-toggle;
  });
  psitool-script = (writeSubbedBin {
    name = "psitool-script";
    src = ./scripts/psitool-script;
  });
  git-browse-origin = (writeSubbedBin {
    name = "git-browse-origin";
    src = ./scripts/git-browse-origin;
    inherit bash;
  });
  git-cleanmerged = (writeSubbedBin {
    name = "git-cleanmerged";
    src = ./scripts/git-cleanmerged;
  });
  tarsnap-dotfiles = (writeSubbedBin {
    name = "tarsnap-dotfiles";
    src = ./scripts/tarsnap-dotfiles;
  });
  xinput-toggle = (writeSubbedBin {
    name = "xinput-toggle";
    src = ./scripts/xinput-toggle;
    inherit bash;
  });
  lock-helper = (writeSubbedBin {
    name = "lock-helper";
    src = ./scripts/lock-helper;
    inherit bash brightnessctl slock coreutils procps libnotify awesome xset;
  });
  rofi-subsuper = (writeSubbedBin {
    name = "rofi-subsuper";
    src = ./scripts/rofi-subsuper;
    inherit bash sed xclip;
  });
  firefox-tempprofile = (writeSubbedBin {
    name = "firefox-tempprofile";
    src = ./scripts/firefox-tempprofile;
    inherit bash coreutils;
  });
}
