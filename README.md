### My system flake for NixOS + Home Manager

## Machines

| Name | Hardware | Role |
|------|----------|------|
| **splinter** | Dell XPS 14 9440 (Intel + Nvidia) | Primary laptop |
| **bebop** | Dell XPS 9310 2-in-1 (Intel) | Secondary laptop |
| **rocksteady** | Vultr VPS | Server (mail, forgejo, gotosocial, etc.) |

## Directory Layout

```
.
├── flake.nix               # Inputs & outputs (machines, overlays, home-manager)
├── plumbing/               # Overlay machinery, all magic happens here
│   ├── default.nix         # Grafts auto-discovery, nixos/hm module lists
│   ├── helpers.nix         # overrideSrc, mkVimPlugin, fromFlake
│   └── README.md
├── grafts/                 # Package additions and overrides — drop files here
│   ├── mpv.nix             # override: example — prev.mpv-unwrapped.override { ... }
│   ├── ionicons.nix        # addition: example — final.callPackage { ... } {}
│   ├── vim-plugins.nix     # set: merges vim plugins into pkgs
│   ├── nixos/              # NixOS modules (auto-applied to all nixosConfigurations)
│   ├── home/               # HM modules (auto-applied to all homeConfigurations)
│   ├── _dormant/           # Inactive packages — move to grafts/ to activate
│   └── README.md
├── machines/               # Machine-specific settings
│   ├── splinter.nix
│   ├── bebop.nix
│   ├── rocksteady.nix
│   └── README.md
└── config/                 # All configurations
    ├── nixos/
    │   ├── base.nix        # Shared base: overlays, nix settings, registry
    │   ├── common.nix      # All machines: locale, nix, users, packages
    │   ├── laptop/         # Shared laptop config
    │   ├── server/         # Server config
    │   └── helper-modules/ # Reusable NixOS modules
    ├── home/
    │   ├── home.nix        # HM entry point
    │   ├── common.nix      # Orchestrator
    │   └── ...
    └── README.md
```

## How to Override or Add a Package

**Expose a flake package or pin a nixpkgs source (no graft file needed):**

Name the input `<pkgname>-src` in `flake.nix`. The `passthrough-overlay` handles it automatically — new packages appear as `pkgs.<pkgname>`; `flake = false` inputs where `<pkgname>` exists in nixpkgs pin that package's source in-place.

**Override or add a package from scratch:**

Create `grafts/<pkgname>.nix`. It is auto-discovered — **no other file needs editing**.

The file receives `{ final, prev, inputs, helpers, ... }`:

```nix
# grafts/mpv.nix — override existing nixpkgs package
{ prev, ... }:
prev.mpv-unwrapped.override { ffmpeg = prev.ffmpeg_6-full; }

# grafts/mytool.nix — add new package
{ final, ... }:
final.callPackage ({ stdenv, ... }: stdenv.mkDerivation { ... }) {}

# grafts/greenclip.nix — pin source to flake input
{ prev, inputs, helpers, ... }:
helpers.overrideSrc prev.greenclip inputs.greenclip-src
```

See `grafts/README.md` for full documentation.

## How to Add a NixOS or Home-Manager Module

Drop a `.nix` file in `grafts/nixos/` (NixOS) or `grafts/home/` (home-manager). It is auto-applied to all configurations.

## Module Hierarchy

```
config/nixos/base.nix (all machines — overlays + nix settings)
└── config/nixos/common.nix (locale, nix, users, packages)
    ├── config/nixos/laptop/common.nix (splinter + bebop)
    │   └── machines/{splinter,bebop}.nix (kernel, GPU, boot, disk)
    └── config/nixos/server/common.nix (rocksteady)
        └── machines/rocksteady.nix (boot, network)
```

## Usage

```bash
# Build/switch NixOS
nixos-rebuild build --flake .#splinter
nixos-rebuild switch --flake .#splinter

# Build/switch home-manager
home-manager build --flake .#gurkan@splinter
home-manager switch --flake .#gurkan@splinter

# Build a graft package
nix build .#ionicons
nix build .#remark42
```
