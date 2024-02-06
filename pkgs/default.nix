# Can build them using 'nix build .#pkgname', stuff I'd like to "pin" their versions etc.
# Normally the "packages" are defined under overlays, which has their inputs defined in main flake.nix
{pkgs, ...}: {
  ionicons = pkgs.callPackage ./ionicons.nix {};
  lineicons = pkgs.callPackage ./lineicons.nix {};
  adminapi = pkgs.python3Packages.callPackage ./adminapi.nix {};
  tapop100 = pkgs.python3Packages.callPackage ./tapop100.nix {};
  # kufur-generator = pkgs.python3Packages.callPackage ./kufur-generator.nix {};
  # comar-generator = pkgs.python3Packages.callPackage ./comar-generator.nix {};
  # anayasaya-noldu = pkgs.python3Packages.callPackage ./anayasaya-noldu.nix {};
  hugo-83 = pkgs.python3Packages.callPackage ./hugo-83.nix {};
  hugo-56 = pkgs.python3Packages.callPackage ./hugo-56.nix {};
  remark42 = pkgs.callPackage ./remark42.nix {};
}
