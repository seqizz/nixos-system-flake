{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    ./lib/common.nix
  ];

  nixpkgs = {
    # All overlays defined in overlays/default.nix (single source of truth)
    overlays = outputs.overlays.all;
    config = {
      allowUnfree = true;
    };
  };

  home = {
    stateVersion = "20.09";
    username = "gurkan";
    homeDirectory = "/home/gurkan";
  };
}
