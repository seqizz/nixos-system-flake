# Requires: inputs.nixos-plymouth-src in flake.nix
{final, inputs, ...}:
final.callPackage ({stdenv}:
  stdenv.mkDerivation {
    name = "nixos-blur";
    version = "unstable-2022-07-08";

    src = inputs.nixos-plymouth-src;

    configurePhase = "mkdir -p $out/share/plymouth/themes";
    installPhase = "cp -r nixos-blur $out/share/plymouth/themes/";
  }) {}
