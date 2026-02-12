# Base microVM configuration function
# Usage: import ./microvm-base.nix { hostName = "..."; ipAddress = "..."; tapId = "..."; mac = "..."; }
# shareSlots: number of generic virtiofs share slots (bind-mounted dynamically by wrapper)
{
  hostName,
  ipAddress,
  tapId,
  mac,
  shareSlots ? 4,
}: {
  config,
  lib,
  pkgs,
  ...
}: {
  microvm = {
    hypervisor = "cloud-hypervisor";
    vcpu = 4;
    mem = 4096;

    shares =
      # Host's /nix/store shared read-only; writableStoreOverlay creates
      # an overlay at /nix/store combining this and /nix/.rw-store
      [
        {
          tag = "ro-store";
          source = "/nix/store";
          mountPoint = "/nix/.ro-store";
          proto = "virtiofs";
        }
      ]
      # Generic share slots (bind-mounted dynamically by wrapper)
      ++ lib.genList (i: {
        tag = "share-${toString i}";
        source = "/devel/microvms/${hostName}/share-${toString i}";
        mountPoint = "/home/gurkan/mnt/${toString i}";
        proto = "virtiofs";
      }) shareSlots
      ++ [
        # Claude config (always available, harmless if unused)
        {
          tag = "claude-state";
          source = "/home/gurkan/.claude";
          mountPoint = "/home/gurkan/.claude";
          proto = "virtiofs";
        }
        # zsh dotfiles (symlinked to ~/.zshrc in guest)
        {
          tag = "zsh-dotfiles";
          source = "/home/gurkan/syncfolder/dotfiles/zsh";
          mountPoint = "/home/gurkan/.zsh-dotfiles";
          proto = "virtiofs";
        }
        # SSH host keys (persistent across VM restarts)
        {
          tag = "ssh-keys";
          source = "/devel/microvms/${hostName}/ssh-host-keys";
          mountPoint = "/etc/ssh/host-keys";
          proto = "virtiofs";
        }
      ];

    volumes = [
      {
        image = "/var/lib/microvms/${hostName}/var.img";
        mountPoint = "/var";
        size = 8192;
      }
    ];

    writableStoreOverlay = "/nix/.rw-store";

    interfaces = [
      {
        type = "tap";
        id = tapId;
        inherit mac;
      }
    ];
  };

  # Fix for microvm shutdown hang (issue #170):
  # Without this, systemd tries to unmount /nix/store during shutdown,
  # but umount lives in /nix/store, causing a deadlock.
  systemd.mounts = [
    {
      what = "store";
      where = "/nix/store";
      overrideStrategy = "asDropin";
      unitConfig.DefaultDependencies = false;
    }
  ];

  networking = {
    hostName = hostName;
    useDHCP = false;
    useNetworkd = true;
    firewall.enable = false;
  };

  systemd.network = {
    enable = true;
    networks."20-eth" = {
      matchConfig.Type = "ether";
      address = ["${ipAddress}/24"];
      gateway = ["192.168.83.1"];
      dns = ["192.168.83.1"];
    };
  };

  services.resolved.enable = true;

  users = {
    groups.gurkan.gid = 1000;
    users.gurkan = {
      isNormalUser = true;
      uid = 1000;
      group = "gurkan";
      shell = pkgs.zsh;
      home = "/home/gurkan";
      # Allow passwordless sudo inside VM
      extraGroups = ["wheel"];
      openssh.authorizedKeys.keys = [
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBAi/oDOeECLfCHJ1TcmB22Bw8mH4zH6XjQxmmHpX/nCMzefbfLai7Ht/CzPwddgSQOVTp+alhhaEpBXtczid/qE= PIV AUTH pubkey"
      ];
    };
  };
  security.sudo.wheelNeedsPassword = false;
  programs.zsh.enable = true;

  # Symlink .zshrc from shared dotfiles
  system.activationScripts.zshrc-link.text = ''
    ln -sfn /home/gurkan/.zsh-dotfiles/.zshrc /home/gurkan/.zshrc
  '';

  services.openssh = {
    enable = true;
    hostKeys = [
      {
        path = "/etc/ssh/host-keys/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };
}
