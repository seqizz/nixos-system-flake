# Overlay machinery and module auto-discovery.
# Normally you don't edit this file — drop files in grafts/ instead.
{inputs, ...}: let
  lib = inputs.nixpkgs.lib;
in rec {
  # Single overlay that auto-discovers all grafts/*.nix.
  # Each file receives { final, prev, inputs, helpers } and returns a derivation or path,
  # becoming pkgs.<filename-without-.nix>.
  # Exception: vim-plugins.nix returns a set of plugins and is merged directly.
  #
  # Uses lib.mapAttrs' (lazy) instead of builtins.foldl' (strict).
  # foldl' would force all graft thunks simultaneously while final is still being
  # computed, causing infinite recursion through final.python3Packages etc.
  grafts-overlay = final: prev:
    let
      helpers = import ./helpers.nix {inherit inputs; pkgs = final;};
      graftsDir = ../grafts;
      graftFiles = builtins.readDir graftsDir;
      # Lazy attrset: each value is only evaluated when accessed
      singleGrafts = lib.mapAttrs' (name: _: {
        name = lib.removeSuffix ".nix" name;
        value = import (graftsDir + "/${name}") {inherit final prev inputs helpers;};
      }) (lib.filterAttrs (n: _: lib.hasSuffix ".nix" n && n != "vim-plugins.nix") graftFiles);
    in
      singleGrafts
      # vim-plugins.nix returns a set of plugins — merge directly into pkgs
      // (import (graftsDir + "/vim-plugins.nix") {inherit inputs helpers;});

  # Makes nixpkgs-unstable available as pkgs.unstable.*
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };

  # Drop-in package replacements from grafts/drop-in/<name>/package.nix.
  # Clone an upstream nixpkgs by-name package directory here to replace pkgs.<name>.
  # Each subdirectory must contain package.nix (standard nixpkgs by-name convention).
  drop-in-overlay = final: prev:
    let
      dropInDir = ../grafts/drop-in;
      entries = builtins.readDir dropInDir;
      # Only subdirectories (files are ignored)
      packageDirs = lib.filterAttrs (_: type: type == "directory") entries;
    in
      lib.mapAttrs (name: _:
        prev.callPackage (dropInDir + "/${name}/package.nix") {}
      ) packageDirs;

  # Auto-exposes any input ending in -src (with the suffix stripped) as
  # pkgs.passthrough.<name> — no extra config needed when adding a new flake input.
  # Inputs declared with flake = false fail lazily with a helpful message when accessed.
  # Names not already present in nixpkgs are also injected at the top level so that
  # pkgs.loose works the same as pkgs.passthrough.loose without any explicit graft files.
  passthrough-overlay = final: prev:
    let
      system = final.stdenv.hostPlatform.system;
      srcInputs = lib.filterAttrs (n: _: lib.hasSuffix "-src" n) inputs;
      # Resolve each *-src input. Four cases:
      #   proper flake + not in nixpkgs → expose packages.default, promote to top-level
      #   proper flake + in nixpkgs     → expose packages.default, pkgs.passthrough.X only
      #   flake=false  + in nixpkgs     → pin source of the nixpkgs pkg, promote (replaces it)
      #   flake=false  + not in nixpkgs → throw lazily; use a graft file to build it
      resolved = lib.mapAttrs' (n: input:
        let
          name     = lib.removeSuffix "-src" n;
          isFlake  = input ? packages;
          # Only check attribute existence — forcing prev.${name} (e.g. lib.isDerivation)
          # triggers nixpkgs' by-name fixed-point through self, causing infinite recursion.
          inNixpkgs = prev ? ${name};
        in {
          inherit name;
          value = {
            pkg =
              if !isFlake && inNixpkgs
              then prev.${name}.overrideAttrs (_: { src = input; })
              else if isFlake
              then input.packages.${system}.default
              else throw "${name} is declared with flake = false and has no nixpkgs counterpart — use a graft file to build it";
            promote = (!isFlake && inNixpkgs) || (isFlake && !inNixpkgs);
          };
        }
      ) srcInputs;
      passthroughs = lib.mapAttrs (_: r: r.pkg) resolved;
      newTopLevel  = lib.mapAttrs (_: r: r.pkg) (lib.filterAttrs (_: r: r.promote) resolved);
    in
      newTopLevel // { passthrough = passthroughs; };

  # Combined overlay list — single source of truth for NixOS and home-manager configs
  # passthrough-overlay must come FIRST so its prev = pure nixpkgs (safe for lib.isDerivation).
  # If placed after grafts-overlay, prev contains graft packages that lazily reference final,
  # and forcing their type attribute causes infinite recursion through the fixed-point.
  # drop-in-overlay comes last so it takes precedence over both.
  all = [passthrough-overlay grafts-overlay drop-in-overlay unstable-packages inputs.skyepkgs.overlays.default];

  # Auto-discovered NixOS modules from grafts/nixos/*.nix — applied to all nixosConfigurations
  nixos-modules =
    let dir = ../grafts/nixos;
    in map (n: dir + "/${n}")
      (builtins.filter (lib.hasSuffix ".nix") (builtins.attrNames (builtins.readDir dir)));

  # Auto-discovered home-manager modules from grafts/home/*.nix — applied to all homeConfigurations
  hm-modules =
    let dir = ../grafts/home;
    in map (n: dir + "/${n}")
      (builtins.filter (lib.hasSuffix ".nix") (builtins.attrNames (builtins.readDir dir)));
}
