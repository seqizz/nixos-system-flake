# MicroVM host configuration — generic VM pool
# Splinter-only: not imported from common.nix
{
  config,
  inputs,
  outputs,
  lib,
  pkgs,
  ...
}: let
  vmCount = 4;
  vmNames = map (i: "vmvm-${toString i}") (lib.range 1 vmCount);
in {
  # Bridge for microVMs
  systemd.network = {
    enable = true;
    netdevs."10-microvmbr" = {
      netdevConfig = {
        Name = "microvmbr";
        Kind = "bridge";
      };
    };
    networks."10-microvmbr" = {
      matchConfig.Name = "microvmbr";
      address = ["192.168.83.1/24"];
      networkConfig.ConfigureWithoutCarrier = true;
    };
    # Attach microVM TAP interfaces to the bridge
    networks."11-microvm" = {
      matchConfig.Name = "vm-*";
      networkConfig.Bridge = "microvmbr";
    };
  };

  # Prevent NetworkManager from touching microVM interfaces
  networking.networkmanager.unmanaged = ["microvmbr" "vm-*"];

  # NAT for microVM internet access
  # No externalInterface = masquerade on all (handles wifi/ethernet switching)
  networking.nat = {
    enable = true;
    internalInterfaces = ["microvmbr"];
  };

  # Allow all traffic from microVM bridge
  networking.firewall.trustedInterfaces = lib.mkAfter ["microvmbr"];

  # DNS forwarding: resolved listens on bridge IP for guest DNS
  services.resolved = {
    enable = true;
    extraConfig = ''
      DNSStubListenerExtra=192.168.83.1
    '';
  };

  # Pool of 4 generic VMs: vmvm-1 through vmvm-4
  # IPs: 192.168.83.11 through 192.168.83.14
  microvm.vms = lib.genAttrs vmNames (name: let
    idx = lib.toInt (lib.removePrefix "vmvm-" name);
  in {
    autostart = false;
    specialArgs = {inherit inputs outputs;};
    config = {
      imports = [
        inputs.microvm.nixosModules.microvm
        (import ./microvm-base.nix {
          hostName = name;
          ipAddress = "192.168.83.${toString (10 + idx)}";
          tapId = "vm-vmvm${toString idx}";
          mac = "02:00:00:00:83:${toString (10 + idx)}";
        })
        ./microvm-guest.nix
      ];
      nixpkgs.overlays = [
        outputs.overlays.unstable-packages
      ];
    };
  });

  # vmvm wrapper script
  environment.systemPackages = [
    (pkgs.writers.writePython3Bin "vmvm" {} (builtins.readFile ./vmvm.py))
  ];
}
