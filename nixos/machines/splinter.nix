{
  config,
  pkgs,
  modulesPath,
  lib,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../lib/laptop/common.nix
    ../lib/inno.nix
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
      kernelModules = ["dm-snapshot" "i915"];
      luks.devices = {
        crypted = {
          preLVM = true;
          allowDiscards = true;
          device = "/dev/disk/by-partlabel/disk-main-luks";
        };
      };
    };
    extraModulePackages = [config.boot.kernelPackages.nvidiaPackages.latest];
    kernelPackages = pkgs.unstable.linuxPackages_latest;
    # @Reference, we can "extend" stuff
    # kernelPackages = pkgs.unstable.linuxPackages_latest.extend (final: prev: {
    #   nvidia_x11 = prev.nvidia_x11_beta;
    # });
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
      # "i915.modeset=1"
      "intel_pstate=passive"
      "pcie_aspm=force"
      "i915.enable_fbc=1"
      "i915.enable_psr=2"
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

  # IPU6 tests, not working yet
  hardware.firmware = with pkgs.unstable; [
    ipu6-camera-bins
    ivsc-firmware
  ];

  services.udev.extraRules = ''
    SUBSYSTEM=="intel-ipu6-psys", MODE="0660", GROUP="video"
  '';

  services.v4l2-relayd.instances.ipu6 = {
    enable = true;

    cardLabel = "Intel MIPI Camera";

    extraPackages = [
      pkgs.unstable.gst_all_1.icamerasrc-ipu6epmtl
    ];

    input = {
      pipeline = "icamerasrc";
      format = "NV12";
    };
  };

  hardware = {
    # XXX: Webcam, almost same as above IPU6 section
    # Waiting for https://github.com/NixOS/nixpkgs/pull/332240 to use built-in module
    # ipu6 = {
    # enable = true;
    # platform = "ipu6epmtl";
    # };
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.latest;
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
  services.xserver.videoDrivers = [ "i915" "nvidia" ];
}
