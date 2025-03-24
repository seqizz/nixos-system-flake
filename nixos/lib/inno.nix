{
  config,
  pkgs,
  lib,
  ...
}: let
  secrets = import ./secrets.nix;
in {
  imports = [
    ../lib/laptop/vpnconfig.nix
    ../lib/laptop/wgconfig-inno.nix
  ];

  security.pki.certificates = [
    secrets.innoRootCA
    secrets.innoRootCAECC
    secrets.innoServiceCA
    secrets.innoServiceCAECC
  ];

  hardware.printers.ensurePrinters = secrets.officePrinters;
}
