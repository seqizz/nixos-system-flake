## plumbing/

Overlay machinery and helper functions. **You don't normally edit this.**

| File | Purpose |
|------|---------|
| `default.nix` | Overlay orchestrator: auto-discovers `grafts/*.nix`, builds `passthrough-overlay`, exports `all` overlay list, `nixos-modules`, `hm-modules` |
| `helpers.nix` | Helper functions injected into every graft as `helpers`: `overrideSrc`, `mkVimPlugin`, `fromFlake` |

The exported attrset (`outputs.overlays`) has:
- `all` — overlay list consumed by `nixpkgs.overlays` in all configs
- `nixos-modules` — list of paths from `grafts/nixos/`, auto-appended to all `nixosConfigurations`
- `hm-modules` — list of paths from `grafts/home/`, auto-appended to all `homeConfigurations`

### passthrough-overlay

Any `flake.nix` input ending in `-src` is automatically resolved (suffix stripped) and exposed as `pkgs.passthrough.<name>`. The behaviour depends on whether the input is a proper flake and whether the name exists in nixpkgs:

| Input type | In nixpkgs? | Effect |
|------------|-------------|--------|
| proper flake | no | `packages.default` → promoted to `pkgs.<name>` |
| proper flake | yes | `packages.default` → `pkgs.passthrough.<name>` only |
| `flake = false` | yes | `prev.<name>.overrideAttrs { src = input; }` → promoted (pins source) |
| `flake = false` | no | throws lazily with a helpful message — use a graft file |

This covers both "new package from external flake" and "pin source of existing nixpkgs package" patterns with zero extra config.
