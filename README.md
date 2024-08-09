### My system flake for Nixos + Home manager ❄️

My whole configuration, except some secrets. Complicated but trying to manage with some kind of module structure.

Only annoyance is that I can't use any file which is not staged in git (because of [this](https://github.com/NixOS/nix/pull/6858) nonsense). So as a workaround I'm using `path:///` (see [aliases.nix](./nixos/lib/aliases.nix)).
