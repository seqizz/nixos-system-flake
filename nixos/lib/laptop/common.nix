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
    ./wgconfig.nix
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

  security = {
    sudo.wheelNeedsPassword = false;
    pki.certificates = [
      ''
        TrueNAS local CA
        =========
        -----BEGIN CERTIFICATE-----
        MIIDzzCCAregAwIBAgIDP7ImMA0GCSqGSIb3DQEBCwUAMG8xCzAJBgNVBAYTAkdH
        MRAwDgYDVQQIDAdIYW1idXJnMRcwFQYDVQQHDA5IYWFhYW1idXV1dXJyZzEPMA0G
        A1UECgwGTXlzZWxmMSQwIgYJKoZIhvcNAQkBFhV0ZXJyYW1hc3RlckBndXJrYW4u
        aW4wIBcNMjUwNDE1MTk0NjI1WhgPMjA1MjA4MzAxOTQ2MjVaMG8xCzAJBgNVBAYT
        AkdHMRAwDgYDVQQIDAdIYW1idXJnMRcwFQYDVQQHDA5IYWFhYW1idXV1dXJyZzEP
        MA0GA1UECgwGTXlzZWxmMSQwIgYJKoZIhvcNAQkBFhV0ZXJyYW1hc3RlckBndXJr
        YW4uaW4wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCO8b/bUDpHVfO8
        UeQrbXMEUF6l1+W5NfRG2zhcV+sRaVgh9uyZ+tFVS6C1Wr1eh8dON51FbIH7E7jK
        t/TTBwKbgXa02BkJSJDT2W2RniSpBfjt18y2lJMnJUkZa0+TBQ4WuA/JEm9ieJM/
        cE6OLttiRlGhSapzRHdHxMT3J440Wq/VsTXOcp11TqIIvFxCTHqR6h0PRoKjrrHq
        4vklI1Th1TMYA1t4zWmDdIfWST3C0cAscOPX7LIgfc24SPT0BR8Ocm0imaahTQuz
        ZY75MDuBIYcunRWFZ0kKJma8h6FoMFkB686g3GOYMA07XCV0E2UZ3YAM499neBkN
        YExMsZjjAgMBAAGjcjBwMBYGA1UdEQQPMA2CC2JpZ2NodW5nLnVzMB0GA1UdDgQW
        BBRFF9xb9Ghw1xrDM/AdEJbiNX4HeTAPBgNVHRMBAf8EBTADAQH/MBYGA1UdJQEB
        /wQMMAoGCCsGAQUFBwMBMA4GA1UdDwEB/wQEAwIBBjANBgkqhkiG9w0BAQsFAAOC
        AQEASCLdVu/j1rblfRNlthBZBQV3mubjbjdvdKO8usrNzw4PMvEoXP6OX79jqI8A
        rY6yoOEm5XNlRUeuET1aahMZQARAH5kYoDbkX1ok8pqG5YvTyoSwLbimdOqR1OfY
        E+FpuPMXw1BH8PciQTDgjX8PqKdFXVvbiWc6Pjz941rnGlVRpKshAmo2JEFbXBFb
        0mHYok+RLor70aVWMDoLwU3icVwbvfqfTaObtkAPp7Zd9lmvjxHxDBJWOrqlwcEL
        IVimxBw9Xp+rPYNmf7WVPi70wRdFQkcuPOJ6obCLzeOnvzLIRK3NfifSu9/+yncK
        w+6a1Fjbzw6UMDvgjt2Z1o/kAA==
        -----END CERTIFICATE-----
      ''
    ];
  };

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
