# Can build them using 'nix build .#pkgname'
{pkgs, ...}: {
  # TODO: Move the sources to inputs
  nixos-plymouth = pkgs.callPackage ./nixos-plymouth.nix {};
  loose = pkgs.callPackage ./loose.nix {};
  ionicons = pkgs.callPackage ./ionicons.nix {};
  lineicons = pkgs.callPackage ./lineicons.nix {};
  adminapi = pkgs.python3Packages.callPackage ./adminapi.nix {};
  tapop100 = pkgs.python3Packages.callPackage ./tapop100.nix {};
  paoutput = pkgs.callPackage ./paoutput.nix {};
  pinentry-rofi = pkgs.callPackage ./pinentry-rofi.nix {};
}
