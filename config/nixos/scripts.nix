{ pkgs, ... }:
let
  writeSubbedBin =
    (import ./helper-modules/writeSubbedBin.nix {
      pkgs = pkgs;
    }).writeSubbedBin;

  awk = pkgs.gawk;
  bash = pkgs.bash;
  brightnessctl = pkgs.brightnessctl;
  coreutils = pkgs.coreutils;
  git = pkgs.git;
  grep = pkgs.gnugrep;
  iiosensorproxy = pkgs.iio-sensor-proxy;
  inotifytools = pkgs.inotify-tools;
  libnotify = pkgs.libnotify;
  procps = pkgs.procps;
  sed = pkgs.gnused;
  slock = pkgs.slock;
  xinput = pkgs.xorg.xinput;
  xrandr = pkgs.xorg.xrandr;
in
{
  environment.systemPackages = with pkgs; [
    (writeSubbedBin {
      name = "oscyank";
      src = ./scripts/oscyank;
    })
    (writeSubbedBin {
      name = "git-default-branch";
      src = ./scripts/git-default-branch;
      inherit git sed;
    })
    # No substitutions on purpose: sysclean looks up nix, sudo and
    # llm-custody-toolbox on PATH, because the host's own nix is the one that
    # matches the running daemon and the toolbox only exists where Home
    # Manager installed it. See the script's own header.
    (writeSubbedBin {
      name = "sysclean";
      src = ./scripts/sysclean;
    })
  ];
}
