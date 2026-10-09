{
  description = "mysystemflake 🕺";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-26.05/nixexprs.tar.zst";
    nixpkgs-unstable.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
    # Historical nixpkgs revisions for frozen grafts (grafts/<name>@<ref>.nix).
    # Declares no inputs of its own (revisions are fetched lazily), so nothing to follow.
    nixpkgs-multiverse.url = "github:fzakaria/nixpkgs-multiverse";
    # nixpkgs-previous.url = "github:nixos/nixpkgs/nixos-25.11";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nur.url = "github:nix-community/NUR";

    skyepkgs.url = "github:skyethepinkcat/skyepkgs";
    skyepkgs.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nocruft = {
      url = "git+https://git.gurkan.in/gurkan/nocruft";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    trayplay-src = {
      url = "git+https://git.gurkan.in/gurkan/trayplay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # llm-related packages
    llm-custody = {
      url = "git+https://git.gurkan.in/gurkan/llm-custody.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pi-nix = {
      url = "github:lukasl-dev/pi.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rpiv-mono-src = {
      url = "github:juicesharp/rpiv-mono";
      flake = false;
    };

    # wezterm = {
    # url = "github:wez/wezterm?dir=nix";
    # inputs.nixpkgs.follows = "nixpkgs";
    # };

    # sd-switch-src.url = "sourcehut:~rycee/sd-switch";

    lain-src = {
      url = "github:lcpz/lain";
      flake = false;
    };

    picom-src = {
      url = "github:yshui/picom/next";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    greenclip-src = {
      url = "github:erebe/greenclip";
      flake = false;
    };

    awesomewm-src = {
      url = "github:awesomewm/awesome";
      flake = false;
    };

    serveradmin-src = {
      url = "github:innogames/serveradmin";
      flake = false;
    };

    slock-flexipatch-src = {
      url = "git+https://git.gurkan.in/gurkan/slock-flexipatch.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    loose-src = {
      url = "git+https://git.gurkan.in/gurkan/loose.git";
      # url = "git+https://git.gurkan.in/gurkan/loose.git?ref=g_uvtime";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    skillissue-src = {
      url = "git+https://git.gurkan.in/gurkan/skillissue.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    yidlehook-src = {
      url = "git+https://git.gurkan.in/gurkan/yidlehook.git";
      flake = false;
    };

    lol-plymouth-src = {
      url = "git+https://git.gurkan.in/gurkan/lol-plymouth.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vimwiki-markdown-src = {
      url = "github:WnP/vimwiki_markdown";
      flake = false;
    };

    # Vim plugins
    vim-yadi-src = {
      url = "github:timakro/vim-yadi";
      flake = false;
    };
    coc-ruff-src = {
      url = "github:yaegassy/coc-ruff";
      flake = false;
    };
    vim-colorschemes-forked-src = {
      url = "github:EvitanRelta/vim-colorschemes";
      flake = false;
    };
    copilot-src = {
      url = "github:github/copilot.vim";
      flake = false;
    };
    undowarn-src = {
      url = "github:arp242/undofile_warn.vim";
      flake = false;
    };
    smoothcursor-src = {
      url = "github:gen740/SmoothCursor.nvim";
      flake = false;
    };

    # Yazi plugins
    yazi-xclip-systemclipboard-src = {
      url = "git+https://git.gurkan.in/gurkan/xclip-system-clipboard.yazi.git";
      flake = false;
    };

    # Pi extensions
    pi-web-access-src = {
      url = "github:nicobailon/pi-web-access";
      flake = false;
    };
    pi-tool-repair-src = {
      url = "github:monotykamary/pi-tool-repair";
      flake = false;
    };

  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nur,
      disko,
      loose-src,
      yidlehook-src,
      nix-index-database,
      simple-nixos-mailserver,
      # wezterm,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      lib = nixpkgs.lib;
      systems = [ "x86_64-linux" ];
      forAllSystems = lib.genAttrs systems;
      # Overlay orchestrator + module auto-discovery
      flakeModules = import ./plumbing { inherit inputs; };
    in
    {
      # Grafts that add new packages, accessible via 'nix build .#pkgname'.
      # Overrides (grafts using 'prev') are excluded — they apply via the overlay
      # but forcing them here would fail if the upstream pkg doesn't exist in nixpkgs.
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = flakeModules.all;
            config.allowUnfree = true;
          };
        in
        lib.filterAttrs (_: lib.isDerivation) (
          lib.listToAttrs (
            map (g: {
              name = g.name;
              value = pkgs.${g.name} or null;
            }) (builtins.filter (g: !g.isOverride) flakeModules.graftAdditions)
          )
        )
      );

      # Overlays — single source of truth for nixpkgs.overlays in all configs
      # outputs.overlays.all is consumed by config/nixos/base.nix and config/home/home.nix
      overlays = flakeModules;

      nixosConfigurations = {
        splinter = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            disko.nixosModules.disko
            # { disko.devices.disk.disk1.device = "/dev/nvme0n1"; }
            nur.modules.nixos.default
            nix-index-database.nixosModules.nix-index
            ./config/nixos/base.nix
            ./machines/splinter.nix
          ]
          ++ flakeModules.nixos-modules; # grafts/nixos/ modules auto-applied
        };
        bebop = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            nur.modules.nixos.default
            nix-index-database.nixosModules.nix-index
            ./config/nixos/base.nix
            ./machines/bebop.nix
          ]
          ++ flakeModules.nixos-modules;
        };
        rocksteady = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            simple-nixos-mailserver.nixosModules.mailserver
            nix-index-database.nixosModules.nix-index
            ./config/nixos/base.nix
            ./machines/rocksteady.nix
          ]
          ++ flakeModules.nixos-modules;
        };
      };

      # No homeConfigurations: Home Manager is wired in as a NixOS module from
      # config/nixos/home-manager.nix (laptops only). A standalone profile pins
      # osConfig to the parent nixosConfiguration, which makes options set in a
      # specialisation invisible to userland. Build/switch userland with
      # nixos-rebuild.
    };
}
