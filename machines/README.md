## machines/

Per-machine hardware configuration: kernel, GPU, boot, disk layout.

| File | Machine | Hardware |
|------|---------|---------|
| `splinter.nix` | Dell XPS 14 9440 | Intel + Nvidia (offload), LUKS, disko |
| `bebop.nix` | Dell XPS 9310 2-in-1 | Intel only, LUKS, btrfs |
| `rocksteady.nix` | Vultr VPS | GRUB, ext4 |
| `splinter-disko.nix` | splinter disk layout | btrfs partition scheme |
| `ipudrivers.nix` | IPU6 camera driver | splinter camera support |

All machine files import from `../config/nixos/` for shared configuration.
