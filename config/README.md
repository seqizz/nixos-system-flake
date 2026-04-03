## config/

All NixOS system and home-manager configuration modules.

### config/nixos/

NixOS system configuration, shared across machines.

| File / Dir | Purpose |
|-----------|---------|
| `base.nix` | Shared base: applies overlays, configures nix settings, registry |
| `common.nix` | All-machine config: locale, nix, users, journald, monitoring |
| `laptop/` | Shared laptop config (splinter + bebop): hardware, networking, services, virt, xserver, etc. |
| `server/` | Server config (rocksteady): mail, forgejo, gotosocial, bots, etc. |
| `helper-modules/` | Reusable NixOS module definitions: WireGuard, VPN, Telegram bots, etc. |

### config/home/

Home-manager configuration.

| File | Purpose |
|------|---------|
| `home.nix` | Entry point, applies overlays |
| `common.nix` | Orchestrator, imports all modules conditionally |
| `packages.nix` | User packages |
| `programs.nix` | Git, yazi, rofi, etc. |
| `services.nix` | User services (syncthing, tarsnap) |
| `xserver.nix` | Display configuration |
