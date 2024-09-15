{
  config,
  pkgs,
  modulesPath,
  lib,
  ...
}:
let

      fucknvidia = config.boot.kernelPackages.nvidiaPackages.mkDriver {
        version = "555.58.02";
        sha256_64bit = "sha256-xctt4TPRlOJ6r5S54h5W6PT6/3Zy2R4ASNFPu8TSHKM=";
        sha256_aarch64 = "sha256-wb20isMrRg8PeQBU96lWJzBMkjfySAUaqt4EgZnhyF8=";
        openSha256 = "sha256-8hyRiGB+m2hL3c9MDA/Pon+Xl6E788MZ50WrrAGUVuY=";
        settingsSha256 = "sha256-ZpuVZybW6CFN/gz9rx+UJvQ715FZnAOYfHn5jt5Z2C8=";
        persistencedSha256 = "sha256-a1D7ZZmcKFWfPjjH1REqPM5j/YLWKnbkP9qfRyIyxAw=";
      };
in
{
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
    extraModulePackages = [fucknvidia];
    # extraModulePackages = [config.boot.kernelPackages.nvidia_x11_production];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelPatches = [
      {
        name = "fuck-your-soundwire";
        patch = pkgs.fetchurl {
          url = "https://github.com/torvalds/linux/commit/233a95fd574fde1c375c486540a90304a2d2d49f.diff";
          hash = "sha256-E7K1gLmjwvk93m/dom19gXkBj3/o+5TLZGamv9Oesv0=";
        };
      }
    ];
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
}
