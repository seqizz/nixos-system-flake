# Can build them using 'nix build .#pkgname', stuff I'd like to "pin" their versions etc.
# Normally the "packages" are defined under overlays, which has their inputs defined in main flake.nix
{pkgs, ...}: {
  ionicons = pkgs.callPackage ./ionicons.nix {};
  lineicons = pkgs.callPackage ./lineicons.nix {};
  adminapi = pkgs.python3Packages.callPackage ./adminapi.nix {};
  tapop100 = pkgs.python3Packages.callPackage ./tapop100.nix {};
}
