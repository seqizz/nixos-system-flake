### My system flake for Nixos + Home manager ❄️

I am able to switch to flakes at last. There are some gimmicks left here and there, but now it's at least tidier than the classical way.

Only annoyance is that I can't use any file which is not staged in git. So as a hack I'm using `path:///` nonsense (see [aliases.nix](./nixos/lib/aliases.nix)).
