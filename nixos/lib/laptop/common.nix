{
  config,
  lib,
  pkgs,
  ...
}: let
  secrets = import ../secrets.nix;
in {
  imports = [
    ../common.nix

    # ./dnscrypt.nix
    ./fonts.nix
    ./hardware.nix
    ./iphone.nix
    ./networking.nix
    ./packages.nix
    ./printing.nix
    ./services.nix
    ../snapper.nix # Called from common dir, maybe one day again..
    ./sound.nix
    ./virt.nix
    ./xserver.nix
    ./yubikey.nix
  ];

  console = {
    keyMap = "trq";
    earlySetup = true;
    # Good for HiDPI on TTY
    font = "latarcyrheb-sun32";
  };

  boot.plymouth = {
    enable = true;
    theme = "lol";
    themePackages = [pkgs.lol-plymouth];
  };

  security.sudo.wheelNeedsPassword = false;

  users = {
    groups.gurkan.gid = 1000;
    users = {
      gurkan = {
        isNormalUser = true;
        uid = 1000;
        shell = pkgs.zsh;
        createHome = true;
        home = "/home/gurkan";
        group = "gurkan";
        extraGroups = [
          "adbusers"
          "adm"
          "audio"
          "disk"
          "docker"
          "incus-admin"
          "input"
          "libvirtd"
          "networkmanager"
          "vboxusers"
          "video"
          "wheel"
        ];
        hashedPassword = secrets.gurkanPassword;
      };
      root = {
        hashedPassword = secrets.rootPassword;
      };
    };
  };

  boot = {
    # Powersave
    extraModprobeConfig = lib.mkMerge [
      # "options snd_hda_intel power_save=1 power_save_controller=Y"
      # "options iwlwifi power_save=1 uapsd_disable=1 power_level=5"
      # "options snd_hda_codec_hdmi enable_silent_stream=1"
      # "options i915 enable_dc=4 enable_fbc=1 enable_guc=2 enable_psr=1 disable_power_well=1"
      "options iwlmvm power_scheme=3"
    ];
    # kernelParams = ["intel_pstate=disable"];
    # I have more than enough memory here
    kernel.sysctl = {
      "vm.swappiness" = 0;
    };
  };

  # @Reference: If I need to move machines around
  # networking.firewall.allowedTCPPorts = [8443];
  virtualisation = {
    libvirtd = {
      enable = true;
      onBoot = "ignore";
    };
    incus = {
      enable = true;
      ui.enable = true;
      preseed = {
        config = {
          "core.https_address" = "127.0.0.1:8443";
        };
        networks = [
          {
            description = "My Incus network";
            config = {
              "ipv4.address" = "192.168.200.1/24";
              "ipv4.nat" = "true";
            };
            name = "incusbr0";
            type = "bridge";
          }
        ];
        profiles = [
          {
            description = "My Incus profile";
            devices = {
              eth0 = {
                "name" = "eth0";
                "nictype" = "bridged";
                "parent" = "incusbr0";
                "type" = "nic";
              };
              root = {
                "path" = "/";
                "pool" = "default";
                "type" = "disk";
              };
            };
            name = "default";
          }
        ];
        storage_pools = [
          {
            config = {
              size = "16GiB";
              source = "/var/lib/incus/disks/default.img";
            };
            description = "My Incus storage";
            name = "default";
            driver = "btrfs";
          }
        ];
      };
    };
  };
}
