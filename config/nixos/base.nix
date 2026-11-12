# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  # You can import other NixOS modules here
  # imports = [
  # ];

  nixpkgs = {
    # You can add overlays here
    # All overlays defined in plumbing/default.nix (single source of truth)
    overlays = outputs.overlays.all;
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
      allowUnsupportedSystem = true;
    };
  };

  # Register the nixpkgs trees (nixpkgs, nixpkgs-unstable, ...) so nix3 and
  # legacy commands resolve them to this flake's pinned revisions.
  # Only those: every registered input becomes part of the system closure via
  # /etc/nix/registry.json and /etc/nix/path, so registering all inputs would
  # keep every tool source tree alive. nixpkgs-multiverse is a library flake,
  # not a package set, so it is useless as a registry or NIX_PATH entry.
  nix.registry = lib.mapAttrs (_: flake: { inherit flake; }) (
    lib.filterAttrs (
      name: _: (name == "nixpkgs" || lib.hasPrefix "nixpkgs-" name) && name != "nixpkgs-multiverse"
    ) inputs
  );

  # This will additionally add your inputs to the system's legacy channels
  # Making legacy nix commands consistent as well, awesome!
  nix.nixPath = [ "/etc/nix/path" ];
  environment.etc = lib.mapAttrs' (name: value: {
    name = "nix/path/${name}";
    value.source = value.flake;
  }) config.nix.registry;

  nix.settings = {
    experimental-features = "nix-command flakes";
  };
}
