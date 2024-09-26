### My system flake for Nixos + Home manager ❄️

My whole configuration, except some secrets. Complicated but trying to manage with some kind of module structure.

```
.
├── home-manager
│   └── lib
│       ├── config_files
│       ├── helper-modules
│       ├── packages
│       └── scripts
├── modules
│   ├── home-manager
│   └── nixos
├── nixos
│   ├── lib
│   │   ├── helper-modules
│   │   ├── laptop
│   │   ├── scripts
│   │   └── server
│   └── machines
├── overlays
└── pkgs
```
