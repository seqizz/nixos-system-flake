# This is just an example, you should generate yours with nixos-generate-config and put it in here.
{
  config,
  pkgs,
  modulesPath,
  lib,
  ...
}: let
  secrets = import ../lib/secrets.nix;
in {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../lib/laptop/common.nix
    ../lib/laptop/vpnconfig.nix # Only imported here
  ];

  # (needed for flakes)
  nixpkgs.hostPlatform = "x86_64-linux";

  networking = {
    hostName = "innodellix";
    networkmanager = {
      plugins = with pkgs; [
        networkmanager-openvpn
      ];
      enableStrongSwan = true;
    };
    # wg-quick.interfaces = {
      # inno0 = secrets.innoWGconfig;
    # };
  };

  system.stateVersion = "20.09";

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        consoleMode = "0";
        configurationLimit = 8;
      };
      efi.canTouchEfiVariables = true;
    };
    plymouth = {
      enable = true;
      theme = "lol";
      themePackages = [pkgs.lol-plymouth];
    };
    initrd = {
      systemd.enable = true;
      availableKernelModules = [
        "ahci"
        "battery"
        "i915"
        "nvme"
        "rtsx_pci_sdmmc"
        "sd_mod"
        "usb_storage"
        "xhci_pci"
      ];
      luks.devices = {
        root = {
          preLVM = true;
          device = "/dev/nvme0n1p2";
        };
      };
    };
    kernelModules = ["kvm-intel" "i915"];
    # kernelPackages = pkgs.linuxPackages_6_7;
    kernelPackages = pkgs.unstable.linuxPackages_latest;
    kernelParams = [
      # prevent the kernel from blanking plymouth out of the fb
      "fbcon=nodefer"
      # disable boot logo if any
      "logo.nologo"
      # tell the kernel to not be verbose
      "quiet"
      # disable systemd status messages
      "rd.systemd.show_status=auto"
      # lower the udev log level to show only errors or worse
      "rd.udev.log_level=3"
      "i915.modeset=1"
      "video=eDP-1:1920x1200@60"
    ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/5474a12e-4fcb-44cb-9107-e7f333392836";
      fsType = "btrfs";
      options = [
        "noatime"
        "nodiratime"
        "discard"
      ];
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/B74E-E1F3";
      fsType = "vfat";
      options = [
        "nofail"
      ];
    };
  };

  powerManagement = {
    cpuFreqGovernor = lib.mkDefault "powersave";
    # Disable hid driver (gyro/accel) while sleeping
    powerDownCommands = ''
      ${pkgs.kmod}/bin/modprobe -r intel_hid
    '';
    resumeCommands = ''
      ${pkgs.kmod}/bin/modprobe intel_hid
    '';
  };

  zramSwap = {
    enable = true;
    memoryPercent = 20;
    swapDevices = 1;
  };

  hardware = {
    # video.hidpi.enable = lib.mkDefault true;
    sensor.iio.enable = true;
    printers.ensurePrinters = secrets.officePrinters;
  };

  # Printing stuff
  services = {
    printing.drivers = with pkgs; [
      hplipWithPlugin
      gutenprint
      splix
    ];
  };
  environment.systemPackages = with pkgs; [
    cifs-utils
  ];
}
