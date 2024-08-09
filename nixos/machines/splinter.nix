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
    ../lib/laptop/wgconfig.nix # Only imported here
    ./splinter-disko.nix
  ];

  # (needed for flakes)
  nixpkgs.hostPlatform = "x86_64-linux";

  networking = {
    hostName = "splinter";
    networkmanager = {
      plugins = with pkgs; [
        networkmanager-openvpn
      ];
      enableStrongSwan = true;
    };
  };

  system.stateVersion = "24.05";

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
        "vmd"
        "nvidia"
      ];
      kernelModules = ["dm-snapshot"];
      luks.devices = {
        crypted = {
          preLVM = true;
          allowDiscards = true;
          device = "/dev/disk/by-partlabel/disk-main-luks";
        };
      };
    };
    kernelModules = ["kvm-intel" "i915" "nvidia"];
    kernelPackages = pkgs.unstable.linuxPackages_latest;
    kernelParams = [
      # prevent the kernel from blanking plymouth out of the fb
      "fbcon=nodefer"
      # disable boot logo if any
      # "logo.nologo"
      # tell the kernel to not be verbose
      "quiet"
      # disable systemd status messages
      "rd.systemd.show_status=auto"
      # lower the udev log level to show only errors or worse
      "rd.udev.log_level=3"
      "i915.modeset=1"
      # "video=eDP-1:1920x1200@60"
    ];
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

  hardware = {
    ipu6 = {
      enable = true;
      platform = "ipu6epmtl";
    };
    sensor.iio.enable = true;
    printers.ensurePrinters = secrets.officePrinters;
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    nvidia = {
      modesetting.enable = true;
      package = config.boot.kernelPackages.nvidiaPackages.beta;
      prime = {
        sync.enable = false;
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
  };

  security.pki.certificates = [
    secrets.innoRootCA
    secrets.innoRootCAECC
    secrets.innoServiceCA
    secrets.innoServiceCAECC
  ];

  # Printing stuff
  services = {
    printing.drivers = with pkgs; [
      hplipWithPlugin
      gutenprint
      splix
    ];
    # SHIT
    xserver.videoDrivers = ["nvidia"];
  };

  environment.systemPackages = with pkgs; [
    cifs-utils
  ];
}
