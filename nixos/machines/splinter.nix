{
  config,
  pkgs,
  modulesPath,
  lib,
  ...
}: let
  fucknvidia = config.boot.kernelPackages.nvidiaPackages.mkDriver {
    version = "565.57.01";
    sha256_64bit = "sha256-buvpTlheOF6IBPWnQVLfQUiHv4GcwhvZW3Ks0PsYLHo=";
    sha256_aarch64 = "sha256-aDVc3sNTG4O3y+vKW87mw+i9AqXCY29GVqEIUlsvYfE=";
    openSha256 = "sha256-/tM3n9huz1MTE6KKtTCBglBMBGGL/GOHi5ZSUag4zXA=";
    settingsSha256 = "sha256-H7uEe34LdmUFcMcS6bz7sbpYhg9zPCb/5AmZZFTx1QA=";
    persistencedSha256 = "sha256-hdszsACWNqkCh8G4VBNitDT85gk9gJe1BlQ8LdrYIkg=";
  };
in {
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
      # kernelModules = ["dm-snapshot" "i915"];
      luks.devices = {
        crypted = {
          preLVM = true;
          allowDiscards = true;
          bypassWorkqueues = true;
          device = "/dev/disk/by-partlabel/disk-main-luks";
        };
      };
    };
    extraModulePackages = [fucknvidia];
    kernelPackages = pkgs.unstable.linuxPackages_latest;
    # @Reference: In case I need to patch the kernel again :(
    # kernelPatches = [
    #   {
    #     name = "fuck-your-soundwire";
    #     patch = pkgs.fetchurl {
    #       url = "https://github.com/torvalds/linux/commit/233a95fd574fde1c375c486540a90304a2d2d49f.diff";
    #       hash = "sha256-E7K1gLmjwvk93m/dom19gXkBj3/o+5TLZGamv9Oesv0=";
    #     };
    #   }
    # ];
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
      # "pcie_aspm=force"
      "i915.enable_fbc=1"
      "i915.enable_psr=2"
      # "video=eDP-1:1920x1200@60"
      # "nvidia-drm.fbdev=1"
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
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    nvidia = {
      modesetting.enable = true;
      # package = config.boot.kernelPackages.nvidia_x11_production;
      package = fucknvidia;
      prime = {
        sync.enable = false;
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
      powerManagement = {
        enable = true;
        finegrained = true;
      };
      open = true;
    };
  };
  # XXX: There is a bug somewhere, this is a workaround
  systemd = {
    extraConfig = "DefaultTimeoutStopSec=10s";
    user.extraConfig = "DefaultTimeoutStopSec=10s";
  };
  services = {
    xserver.videoDrivers = ["i915" "nvidia"];
    tlp.settings = {
      "MAX_LOST_WORK_SECS_ON_BAT" = 15;
      "WOL_DISABLE" = "Y";
      # CPU
      "CPU_SCALING_GOVERNOR_ON_AC" = "performance";
      "CPU_SCALING_GOVERNOR_ON_BAT" = "schedutil";
      "CPU_ENERGY_PERF_POLICY_ON_AC" = "performance";
      "CPU_ENERGY_PERF_POLICY_ON_BAT" = "balance_power";
      "CPU_MIN_PERF_ON_AC" = 0;
      "CPU_MAX_PERF_ON_AC" = 100;
      "CPU_MIN_PERF_ON_BAT" = 0;
      "CPU_MAX_PERF_ON_BAT" = 80;
      # GPU
      "INTEL_GPU_MIN_FREQ_ON_AC" = 1000;
      "INTEL_GPU_MIN_FREQ_ON_BAT" = 100;
      "INTEL_GPU_MAX_FREQ_ON_AC" = 2200;
      "INTEL_GPU_MAX_FREQ_ON_BAT" = 2200;
      "INTEL_GPU_BOOST_FREQ_ON_AC" = 2250;
      "INTEL_GPU_BOOST_FREQ_ON_BAT" = 2250;
    };
  };
  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };
}
