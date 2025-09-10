# Dell XPS 14 9440
{
  config,
  pkgs,
  modulesPath,
  lib,
  ...
}: let
  fucknvidia = config.boot.kernelPackages.nvidiaPackages.mkDriver {
    version = "570.172.08";
    sha256_64bit = "sha256-AlaGfggsr5PXsl+nyOabMWBiqcbHLG4ij617I4xvoX0=";
    sha256_aarch64 = lib.fakeHash;
    openSha256 = "sha256-aTV5J4zmEgRCOavo6wLwh5efOZUG+YtoeIT/tnrC1Hg=";
    settingsSha256 = "sha256-N/1Ra8Teq93U3T898ImAT2DceHjDHZL1DuriJeTYEa4=";
    persistencedSha256 = lib.fakeHash;
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
    kernelPackages = pkgs.linuxPackages_6_12;
    # kernelPackages = pkgs.linuxPackages_latest.extend (self: super: {
    #   ipu6-drivers = super.ipu6-drivers.overrideAttrs (
    #     final: previous: rec {
    #       src = builtins.fetchGit {
    #         url = "https://github.com/intel/ipu6-drivers.git";
    #         ref = "master";
    #         rev = "4bb5b4d8128fbf7f4730cd364a8f7fc13a0ef65b";
    #       };
    #     }
    #   );
    # });
    # @Reference: In case I need to override the kernel
    # Apparently having a USB webcam was too insecure so we had to invent new shit
    # called IPU. I cannot use newer kernels since noone knows what they are doing
    # upstream and WEBCAM DOES NOT WORK! Total dumbfuckery.
    # kernelPackages =
    #   (pkgs.linuxPackagesFor
    #     (pkgs.linux_6_12.override {
    #       argsOverride = rec {
    #         src = pkgs.fetchurl {
    #           url = "mirror://kernel/linux/kernel/v6.x/linux-${version}.tar.xz";
    #           sha256 = "sha256-AZOx2G3TcuyJG655n22iDe7xb8GZ8wCApOqd6M7wxhk=";
    #         };
    #         version = "6.12.1";
    #         modDirVersion = "6.12.1";
    #       };
    #     }))
    #   .extend (_: _: {
    #     ipu6-drivers = config.boot.kernelPackages.callPackage ./ipudrivers.nix {};
    #   });
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
      "quiet"
      # disable systemd status messages
      "rd.systemd.show_status=auto"
      # lower the udev log level to show only errors or worse
      "rd.udev.log_level=3"
      "i915.modeset=1"
      "nvidia.modeset=1"
      "intel_pstate=passive"
      # "pcie_aspm=force"
      "i915.enable_fbc=1"
      "i915.enable_psr=0" # WTF is even this?
      # "video=eDP-1:1920x1200@60"
      "nvidia-drm.fbdev=1"
    ];
    extraModprobeConfig = lib.mkMerge [
      "options nvidia NVreg_UsePageAttributeTable=1 NVreg_PreserveVideoMemoryAllocations=1"
    ];
  };

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

  hardware = {
    ipu6 = {
      # Brain has left the chat
      enable = true;
      platform = "ipu6epmtl";
    };
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    nvidia = {
      modesetting.enable = true;
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
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };
}
