# shredder disk layout, consumed by disko and nixos-anywhere.
#
# vda: single disk for the OS and /shared (mail, DKIM keys, bind zones,
#      service state). /shared is a plain directory on the root filesystem.
#      The VM boots legacy BIOS, so GRUB needs a 1M EF02 partition to embed
#      its core image on a GPT disk. disko derives boot.loader.grub.devices
#      from the EF02 partition, so no grub device is set by hand in
#      shredder.nix.
#      Caution: a nixos-anywhere run formats this disk, so re-running it on a
#      live shredder wipes /shared together with the OS.
{
  disko.devices.disk = {
    main = {
      type = "disk";
      device = "/dev/vda";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "1M";
            type = "EF02";
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = [ "noatime" ];
            };
          };
        };
      };
    };
  };
}
