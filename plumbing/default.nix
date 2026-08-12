# Overlay machinery and module auto-discovery.
# Normally you don't edit this file — drop files in grafts/ instead.
{ inputs, ... }:
let
  lib = inputs.nixpkgs.lib;
in
rec {
  # Parses a graft filename into { name, frozenRef }.
  #   foo.nix       → { name = "foo"; frozenRef = null; }   (normal graft)
  #   foo@REF.nix   → { name = "foo"; frozenRef = "REF"; }  (graftiverse / frozen graft)
  # REF is anything without "/" or "@" — a date (2026-08-08), release or commit.
  parseGraftName =
    fileName:
    let
      base = lib.removeSuffix ".nix" fileName;
      parts = lib.splitString "@" base;
      name = builtins.elemAt parts 0;
      frozenRef = builtins.elemAt parts 1;
    in
    if builtins.length parts == 1 then
      {
        inherit name;
        frozenRef = null;
      }
    else if builtins.length parts > 2 then
      throw "graft '${fileName}': ambiguous filename, only one '@' allowed (<name>@<frozenRef>.nix)"
    else if name == "" || frozenRef == "" then
      throw "graft '${fileName}': both sides of '@' must be non-empty (<name>@<frozenRef>.nix)"
    else
      { inherit name frozenRef; };

  # Single overlay that auto-discovers all grafts/*.nix.
  # Each file receives { final, prev, inputs, helpers } and returns a derivation or path,
  # becoming pkgs.<filename-without-.nix>.
  # Exception: vim-plugins.nix returns a set of plugins and is merged directly.
  #
  # Graftiverse: a file named <name>@<frozenRef>.nix becomes pkgs.<name>, but its
  # final/prev come from a historical nixpkgs resolved by nixpkgs-multiverse at
  # <frozenRef>. The graft body is identical either way, so freezing/unfreezing is
  # just a file rename.
  #
  # Uses lib.mapAttrs' (lazy) instead of builtins.foldl' (strict).
  # foldl' would force all graft thunks simultaneously while final is still being
  # computed, causing infinite recursion through final.python3Packages etc.
  grafts-overlay =
    final: prev:
    let
      helpers = import ./helpers.nix {
        inherit inputs;
        pkgs = final;
      };
      graftsDir = ../grafts;
      graftFiles = builtins.readDir graftsDir;
      graftNames = builtins.attrNames (
        lib.filterAttrs (n: _: lib.hasSuffix ".nix" n && n != "vim-plugins.nix") graftFiles
      );
      parsed = map (file: parseGraftName file // { inherit file; }) graftNames;

      # Frozen grafts get plain historical nixpkgs + our config, no local overlays:
      # feeding this overlay back into a revision it produces would be recursive.
      multiverse = inputs.nixpkgs-multiverse.lib.mkMultiverse {
        system = final.stdenv.hostPlatform.system;
        config = prev.config;
        overlays = [ ];
      };
      # genAttrs values are lazy, so a frozen revision is only fetched/evaluated
      # when the graft using it is actually accessed (and shared between grafts
      # pinned to the same ref).
      frozenUniverses = lib.genAttrs (
        lib.unique (map (g: g.frozenRef) (builtins.filter (g: g.frozenRef != null) parsed))
      ) (ref: multiverse.at ref);

      # Deterministic conflict: refuse mpv.nix and mpv@2026-08-08.nix side by side.
      duplicates = builtins.filter (g: builtins.length g > 1) (
        builtins.attrValues (lib.groupBy (g: g.name) parsed)
      );
      checked =
        if duplicates == [ ] then
          parsed
        else
          throw "duplicate graft target(s): ${
            lib.concatMapStringsSep ", " (
              g: "${(builtins.head g).name} (${lib.concatMapStringsSep " + " (x: x.file) g})"
            ) duplicates
          }";

      # Lazy attrset: each value is only evaluated when accessed
      singleGrafts = builtins.listToAttrs (
        map (g: {
          inherit (g) name;
          value = import (graftsDir + "/${g.file}") {
            final = if g.frozenRef == null then final else frozenUniverses.${g.frozenRef};
            prev = if g.frozenRef == null then prev else frozenUniverses.${g.frozenRef};
            inherit inputs helpers;
          };
        }) checked
      );
    in
    singleGrafts
    # vim-plugins.nix returns a set of plugins — merge directly into pkgs
    // (import (graftsDir + "/vim-plugins.nix") {
      inherit
        final
        prev
        inputs
        helpers
        ;
    });

  # Auto-exposes every flake input named `nixpkgs-<suffix>` as pkgs.<suffix>.*
  # e.g. nixpkgs-unstable → pkgs.unstable, nixpkgs-previous → pkgs.previous
  # nixpkgs-multiverse is excluded: it is a library flake, not a nixpkgs tree,
  # so `import` on it would fail. It is consumed by grafts-overlay instead.
  nixpkgs-channels =
    final: _prev:
    let
      channels = lib.filterAttrs (
        n: _: lib.hasPrefix "nixpkgs-" n && n != "nixpkgs-multiverse"
      ) inputs;
    in
    lib.mapAttrs' (n: input: {
      name = lib.removePrefix "nixpkgs-" n;
      value = import input {
        system = final.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      };
    }) channels;

  # Drop-in package replacements from grafts/drop-in/<name>/package.nix.
  # Clone an upstream nixpkgs by-name package directory here to replace pkgs.<name>.
  # Each subdirectory must contain package.nix (standard nixpkgs by-name convention).
  drop-in-overlay =
    final: prev:
    let
      dropInDir = ../grafts/drop-in;
      # Dir may not exist (git doesn't track empty dirs). Skip cleanly in that case.
      entries = if builtins.pathExists dropInDir then builtins.readDir dropInDir else { };
      # Only subdirectories (files are ignored)
      packageDirs = lib.filterAttrs (_: type: type == "directory") entries;
    in
    lib.mapAttrs (name: _: prev.callPackage (dropInDir + "/${name}/package.nix") { }) packageDirs;

  # Auto-exposes any input ending in -src (with the suffix stripped) as
  # pkgs.passthrough.<name> — no extra config needed when adding a new flake input.
  # Inputs declared with flake = false fail lazily with a helpful message when accessed.
  # Names not already present in nixpkgs are also injected at the top level so that
  # pkgs.loose works the same as pkgs.passthrough.loose without any explicit graft files.
  passthrough-overlay =
    final: prev:
    let
      system = final.stdenv.hostPlatform.system;
      srcInputs = lib.filterAttrs (n: _: lib.hasSuffix "-src" n) inputs;
      # Resolve each *-src input. Four cases:
      #   proper flake + not in nixpkgs → expose packages.default, promote to top-level
      #   proper flake + in nixpkgs     → expose packages.default, pkgs.passthrough.X only
      #   flake=false  + in nixpkgs     → pin source of the nixpkgs pkg, promote (replaces it)
      #   flake=false  + not in nixpkgs → throw lazily; use a graft file to build it
      resolved = lib.mapAttrs' (
        n: input:
        let
          name = lib.removeSuffix "-src" n;
          isFlake = input ? packages;
          # Only check attribute existence — forcing prev.${name} (e.g. lib.isDerivation)
          # triggers nixpkgs' by-name fixed-point through self, causing infinite recursion.
          inNixpkgs = prev ? ${name};
        in
        {
          inherit name;
          value = {
            pkg =
              if !isFlake && inNixpkgs then
                prev.${name}.overrideAttrs (_: {
                  src = input;
                })
              else if isFlake then
                input.packages.${system}.default
              else
                throw "${name} is declared with flake = false and has no nixpkgs counterpart — use a graft file to build it";
            promote = (!isFlake && inNixpkgs) || (isFlake && !inNixpkgs);
          };
        }
      ) srcInputs;
      passthroughs = lib.mapAttrs (_: r: r.pkg) resolved;
      newTopLevel = lib.mapAttrs (_: r: r.pkg) (lib.filterAttrs (_: r: r.promote) resolved);
    in
    newTopLevel // { passthrough = passthroughs; };

  # Combined overlay list — single source of truth for NixOS and home-manager configs
  # passthrough-overlay must come FIRST so its prev = pure nixpkgs (safe for lib.isDerivation).
  # If placed after grafts-overlay, prev contains graft packages that lazily reference final,
  # and forcing their type attribute causes infinite recursion through the fixed-point.
  # drop-in-overlay comes last so it takes precedence over both.
  all = [
    passthrough-overlay
    grafts-overlay
    drop-in-overlay
    nixpkgs-channels
    inputs.skyepkgs.overlays.default
  ];

  # Auto-discovered NixOS modules from grafts/nixos/*.nix — applied to all nixosConfigurations
  # pathExists guard: an empty grafts dir is untracked by git, so it is absent
  # from the flake source snapshot and readDir would throw.
  nixos-modules =
    let
      dir = ../grafts/nixos;
    in
    lib.optionals (builtins.pathExists dir) (
      map (n: dir + "/${n}") (
        builtins.filter (lib.hasSuffix ".nix") (builtins.attrNames (builtins.readDir dir))
      )
    );

  # Auto-discovered home-manager modules from grafts/home/*.nix — applied to all homeConfigurations
  hm-modules =
    let
      dir = ../grafts/home;
    in
    lib.optionals (builtins.pathExists dir) (
      map (n: dir + "/${n}") (
        builtins.filter (lib.hasSuffix ".nix") (builtins.attrNames (builtins.readDir dir))
      )
    );
}
