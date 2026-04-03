{
  config,
  pkgs,
  lib,
  ...
}: let
  secrets = import ./secrets.nix;
in {
  imports = [
    ./laptop/vpnconfig.nix
    ./laptop/wgconfig-inno.nix
  ];

  security.pki.certificates = [
    secrets.innoRootCA
    secrets.innoRootCAECC
    secrets.innoServiceCA
    secrets.innoServiceCAECC
  ];

  hardware.printers.ensurePrinters = secrets.officePrinters;

  networking.networkmanager = {
    plugins = with pkgs; [
      networkmanager-openvpn
      networkmanager-strongswan
    ];
  };

  # Wireguard pushes DNS, but I wanna use my local except for company domains
  services.resolved.enable = true;
}
