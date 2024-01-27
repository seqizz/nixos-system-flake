{
  config,
  pkgs,
  modulesPath,
  lib,
  ...
}: {
  networking.hostName = "rocksteady";

  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ../lib/server/common.nix
  ];

  # (needed for flakes)
  nixpkgs.hostPlatform = "x86_64-linux";

  boot = {
    loader.grub.device = "/dev/vda";
    kernelModules = ["tcp_bbr"];
    kernel.sysctl = {
      "net.ipv4.tcp_congestion_control" = "bbr";
    };
  };

  fileSystems."/" = {
    device = "/dev/vda1";
    fsType = "ext4";
    options = ["noatime"];
  };

  swapDevices = [
    {
      device = "/swapfile";
      size = 2048;
    }
  ];

  system.stateVersion = "20.03";
}
