{prev, ...}: let
  # Intel microcode newer than the one in nixpkgs. Only pulled into a system
  # closure when hardware.cpu.intel.updateMicrocode is on, so no gating needed here.
  version = "20260812";

  # Self-expiring override: once nixpkgs catches up, stop overriding and nag on
  # every eval so this file gets deleted instead of silently pinning an old build.
  obsolete = prev.lib.versionAtLeast prev.microcode-intel.version version;
in
  prev.lib.warnIf obsolete ''
    microcode-intel >= ${version} is now in nixpkgs, grafts/microcode-intel.nix can be removed.
  ''
  (
    if obsolete
    then prev.microcode-intel
    else
      prev.microcode-intel.overrideAttrs (oldAttrs: {
        inherit version;
        src = oldAttrs.src.override {
          tag = "microcode-${version}";
          hash = "sha256-Rw40SNaVSnGenRIkuspVzsFXt17GxPUTsRP86aMI4RM=";
        };
      })
  )
