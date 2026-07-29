{
  config,
  pkgs,
  lib,
  ...
}:
let
  secrets = import ./secrets.nix;
in
{
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

  # ig.local's DNSSEC island of trust
  # Global DNSSEC is intentionally left off; validation is enabled per-link only
  # on the IG WireGuard interfaces (see wgconfig-inno.nix). If I enable
  # globally pihole is freaking out and blocks all unsigned answers :D
  # If the internal ig.local KSK rotates, check secrets.nix for instructions.
  # Emergency-disable: sudo resolvectl dnssec IG-WG-1 no
  environment.etc."dnssec-trust-anchors.d/ig.local.positive".text = ''
    ${secrets.igLocalDS}
  '';

  networking.networkmanager = {
    plugins = with pkgs; [
      networkmanager-openvpn
      networkmanager-strongswan
    ];
  };
}
