## machines/

Per-machine hardware configuration: kernel, GPU, boot, disk layout.

| File | Machine | Hardware |
|------|---------|---------|
| `splinter.nix` | Dell XPS 14 9440 | Intel + Nvidia (offload), LUKS, disko |
| `bebop.nix` | Dell XPS 9310 2-in-1 | Intel only, LUKS, btrfs |
| `rocksteady.nix` | Vultr VPS | GRUB, ext4 |
| `shredder.nix` | VM (rocksteady successor) | GRUB (BIOS), ext4, disko |
| `shredder-disko.nix` | shredder disk layout | single vda, ext4 root (`/shared` on root) |
| `splinter-nvidia.json` | splinter nvidia driver pin | version + hashes, bumped by `nvidia-update` |
| `splinter-disko.nix` | splinter disk layout | btrfs partition scheme |
| `ipudrivers.nix` | IPU6 camera driver | splinter camera support |

All machine files import from `../config/nixos/` for shared configuration.
