{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    ./common.nix
  ];

  nixpkgs = {
    # All overlays defined in plumbing/default.nix (single source of truth)
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
