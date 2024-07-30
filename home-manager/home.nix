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
    overlays = [
      # overlays of own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
      outputs.overlays.oldversion-packages
    ];
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
