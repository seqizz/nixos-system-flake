## grafts/

Package additions and overrides. Drop a `.nix` file here to add or override a package.

### How it works

Every `grafts/*.nix` file is auto-discovered. Each receives `{ final, prev, inputs, helpers, ... }` and returns:
- **A derivation** → becomes `pkgs.<filename-without-.nix>` and is exposed via `nix build .#<name>`
- **An attrset** → merged directly into pkgs (used by `vim-plugins.nix`)
- **A path** → becomes `pkgs.<filename>` (used by `yazi-xclip-systemclipboard.nix`)

Available args:
- `final` — fully resolved pkgs (after all overlays — use for new packages)
- `prev` — original nixpkgs before this overlay (use for overrides)
- `inputs` — all flake inputs
- `helpers.overrideSrc pkg src` — override a package's source from a flake input
- `helpers.mkVimPlugin pname src` — build a vim plugin from a flake input
- `helpers.fromFlake input` — use the default package from another flake's output

### Examples

```nix
# Override existing nixpkgs package
{ prev, ... }:
prev.mpv-unwrapped.override { ffmpeg = prev.ffmpeg_6-full; }

# New package
{ final, ... }:
final.callPackage ({ stdenv, ... }: stdenv.mkDerivation { ... }) {}

# New Python package
{ final, ... }:
final.python3Packages.callPackage ({ buildPythonPackage, ... }: buildPythonPackage { ... }) {}

# Override with pinned source from flake input
{ prev, inputs, helpers, ... }:
helpers.overrideSrc prev.greenclip inputs.greenclip-src
```

### Frozen grafts (graftiverse)

Rename `foo.nix` → `foo@<ref>.nix` to evaluate the same file against historical nixpkgs
(via nixpkgs-multiverse). Contents stay identical; the package is still `pkgs.foo`.

```nix
# grafts/mpv@2026-08-08.nix  → pkgs.mpv built against nixpkgs as of 2026-08-08
{prev, ...}:
prev.mpv-unwrapped.override {
  ffmpeg = prev.ffmpeg_6-full;
}
```

`<ref>`, no `/`, only one `@`:

- `2026-08-12` — a **date always resolves against nixos-unstable** (newest rev on or before it).
  Only unstable revisions are indexed, so this switches the package's branch, not just its age.
- `26.05` — tip of that release branch; changes only when the `nixpkgs-multiverse` input is bumped.
- `2fcb964de67f` — commit, but it must already be in multiverse's index.

There is no way to say "release-26.05 as of a past date" — that history is not indexed. Pin such a
rev as a normal `nixpkgs-<label>` flake input instead.

Having both `foo.nix` and `foo@<ref>.nix` is a hard error. Frozen closures get no security updates
until the ref is bumped.

### Passthrough: flake packages and source pins (no graft file needed)

Name the input `<pkgname>-src` in `flake.nix`. The `passthrough-overlay` in `plumbing/default.nix` handles it automatically:

- **New package** (`pkgname` not in nixpkgs, proper flake) → `pkgs.pkgname` + `pkgs.passthrough.pkgname`
- **Source pin** (`pkgname` in nixpkgs, `flake = false`) → overrides source of `pkgs.pkgname` in-place
- `flake = false` + not in nixpkgs → lazy error; write a graft file instead

```nix
# New package from external flake
mytool-src = { url = "github:someone/mytool"; inputs.nixpkgs.follows = "nixpkgs"; };
# → pkgs.mytool available automatically

# Pin source of existing nixpkgs package
greenclip-src = { url = "github:erebe/greenclip"; flake = false; };
# → pkgs.greenclip built from that commit automatically
```

Use `helpers.fromFlake` in a graft file only when you need non-default flake output or complex `overrideAttrs`.

### Adding a vim plugin

1. Add `plugin-name-src = { url = "..."; flake = false; };` to `flake.nix` inputs
2. Add one line to `grafts/vim-plugins.nix`: `plugin-name = helpers.mkVimPlugin "plugin-name" inputs.plugin-name-src;`

### Subdirectories

- `grafts/nixos/` — NixOS modules, auto-applied to all `nixosConfigurations`
- `grafts/home/` — Home-manager modules, auto-applied to all `homeConfigurations`
- `grafts/drop-in/` — Unmodified nixpkgs package directory copies (see below)
- `grafts/_dormant/` — Inactive packages (broken deps or missing inputs). Move to `grafts/` to activate.

### Drop-in replacements (`grafts/drop-in/`)

Clone an upstream nixpkgs `pkgs/by-name` package directory here to replace it wholesale.
No `.nix` graft file needed — just the directory with `package.nix` inside.

```bash
# Example: replace claude-code with a newer/patched version
# Find the upstream path: nix edit nixpkgs#claude-code
# Copy the whole directory:
cp -r /path/to/nixpkgs/pkgs/by-name/cl/claude-code grafts/drop-in/
# Edit grafts/drop-in/claude-code/package.nix as needed
# That's it — pkgs.claude-code now uses your version
```

Takes precedence over regular grafts. Only `package.nix` is expected (nixpkgs by-name convention).
