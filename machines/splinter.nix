# Dell XPS 14 9440
{
  config,
  pkgs,
  modulesPath,
  lib,
  ...
}:
let
  fucknvidia = config.boot.kernelPackages.nvidiaPackages.mkDriver {
    version = "595.104.02";
    sha256_64bit = "sha256-5CHCAuTHn1jDx/MWG75xRU67PYiTb4ggWg4yfNBMWco=";
    openSha256 = "sha256-FWk5ra2yjz8VAxAA8GXrSoeBj/XC1BKvsKsBKR09joE=";
    settingsSha256 = "sha256-4Kxro6tvI5aX4nu2RspgyBsW+Jq3/VYjSAS5UGdzTCU=";
    persistencedSha256 = lib.fakeHash;
    sha256_aarch64 = lib.fakeHash;
  };
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../config/nixos/laptop/common.nix
    ./splinter-disko.nix
  ];

  # (needed for flakes)
  nixpkgs.hostPlatform = "x86_64-linux";

  networking.hostName = "splinter";

  # Permanent work machine, so no specialisation here.
  local.profiles.work.enable = true;

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
        "nvidia"
        "nvme"
        "rtsx_pci_sdmmc"
        "sd_mod"
        "usb_storage"
        "vmd"
        "xhci_pci"
      ];
      luks.devices = {
        crypted = {
          preLVM = true;
          allowDiscards = true;
          bypassWorkqueues = true;
          device = "/dev/disk/by-partlabel/disk-main-luks";
        };
      };
    };
    extraModulePackages = [ fucknvidia ];
    kernelPackages = pkgs.linuxPackages_latest;
    # kernelPackages = pkgs.linuxPackages_6_18;
    # kernelPackages = pkgs.linuxPackages_latest.extend (self: super: {
    #   kernel = super.kernel.override {
    #     argsOverride = rec {
    #       version = "6.18.6";
    #       modDirVersion = version;
    #       src = pkgs.fetchurl {
    #         url = "mirror://kernel/linux/kernel/v6.x/linux-${version}.tar.xz";
    #         hash = "sha256-RySXGXsvaNTb8bwyzG3GacoiD/TA6w3Dmpz/moj5oxs="; # will fail, gives you real hash
    #       };
    #     };
    #   };
    # });

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
    # Aaaand the real shitshow begins
    kernelParams = [
      # prevent the kernel from blanking plymouth out of the fb
      "fbcon=nodefer"
      "quiet"
      "pm_debug_messages"
      # disable systemd status messages
      "rd.systemd.show_status=auto"
      # lower the udev log level to show only errors or worse
      "rd.udev.log_level=3"
      "intel_pstate=passive"
      "i915.enable_fbc=1"
      "i915.enable_psr=0" # WTF is even this?
      # "plymouth.debug=file:/run/plymouth-debug.log" # @Reference
      # "video=eDP-1:1920x1200@60"
      # "nvidia-drm.fbdev=1"
    ];
    # extraModprobeConfig = lib.mkMerge [
    # "options nvidia NVreg_UsePageAttributeTable=1 NVreg_PreserveVideoMemoryAllocations=1"
    # ];
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
      nvidiaSettings = false;
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
      open = false;
    };
  };
  # XXX: There is a bug somewhere, this is a workaround
  systemd = {
    settings.Manager = {
      DefaultTimeoutStopSec = "10s";
    };
    user.extraConfig = "DefaultTimeoutStopSec=10s";
  };
  services = {
    xserver.videoDrivers = [ "nvidia" ];
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

  # No USB wake ups on this box, something is very buggy.
  systemd.services =
    let
      sleepTargets = [
        "suspend.target"
        "hibernate.target"
        "hybrid-sleep.target"
        "suspend-then-hibernate.target"
      ];
      disableWakeup = description: wakeupAttr: {
        inherit description;
        wantedBy = [ "multi-user.target" ] ++ sleepTargets;
        after = sleepTargets;
        unitConfig.ConditionPathIsWritable = wakeupAttr;
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = false;
          ExecStart = "${pkgs.coreutils}/bin/tee ${wakeupAttr}";
          StandardInput = "data";
          StandardInputText = "disabled";
          StandardOutput = "null";
        };
      };
    in
    {
      disable-awac-wakeup = disableWakeup "Disable AWAC ACPI wakeup source" "/sys/devices/pci0000:00/ACPI000E:00/power/wakeup";
      disable-xhci-wakeup = disableWakeup "Disable xHCI PCI wakeup source" "/sys/devices/pci0000:00/0000:00:14.0/power/wakeup";
    };
}
