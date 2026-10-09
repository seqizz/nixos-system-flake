{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./common.nix
  ];

  # No nixpkgs.* here on purpose: home-manager.useGlobalPkgs is set in
  # config/nixos/home-manager.nix, so pkgs (overlays + allowUnfree) comes from
  # the NixOS config and HM refuses to take nixpkgs options of its own.

  home = {
    stateVersion = "20.09";
    username = "gurkan";
    homeDirectory = "/home/gurkan";
  };
}
