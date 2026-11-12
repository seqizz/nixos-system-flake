# picom from the upstream `next` branch (inputs.picom-src).
# picom exists in nixpkgs, so the passthrough overlay alone only fills
# pkgs.passthrough.picom; this graft makes plain pkgs.picom the upstream build.
{ inputs, helpers, ... }: helpers.fromFlake inputs.picom-src
