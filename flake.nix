{
  description = "mysystemflake 🕺";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # nixpkgs-previous.url = "github:nixos/nixpkgs/nixos-25.05";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nur.url = "github:nix-community/NUR";

    skyepkgs.url = "github:skyethepinkcat/skyepkgs";
    skyepkgs.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # wezterm = {
    # url = "github:wez/wezterm?dir=nix";
    # inputs.nixpkgs.follows = "nixpkgs";
    # };

    sd-switch-src = {
      url = "sourcehut:~rycee/sd-switch";
    };

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
      flake = false;
    };

    loose-src = {
      url = "git+https://git.gurkan.in/gurkan/loose.git";
      # url = "git+https://git.gurkan.in/gurkan/loose.git?ref=g_uvtime";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    yidlehook-src = {
      url = "git+https://git.gurkan.in/gurkan/yidlehook.git";
      flake = false;
    };

    lol-plymouth-src = {
      url = "git+https://git.gurkan.in/gurkan/lol-plymouth.git";
      flake = false;
    };

    vimwiki-markdown-src = {
      url = "github:WnP/vimwiki_markdown";
      flake = false;
    };

    # xidlehook-src = {
    # url = "github:realSaltyFish/xidlehook";
    # };

    # Vim plugins
    vim-yadi-src = {
      url = "github:timakro/vim-yadi";
      flake = false;
    };
    # yanky-src = {
    # url = "github:gbprod/yanky.nvim";
    # flake = false;
    # };
    # leap-src = {
    #   url = "git+ssh://codeberg.org/andyg/leap.nvim";
    #   flake = false;
    # };
    trailblazer-src = {
      url = "github:LeonHeidelbach/trailblazer.nvim";
      flake = false;
    };
    coc-ruff-src = {
      url = "github:yaegassy/coc-ruff";
      flake = false;
    };
    commentnvim-src = {
      url = "github:numToStr/Comment.nvim";
      flake = false;
    };
    telescope-file-browser-src = {
      url = "github:nvim-telescope/telescope-file-browser.nvim";
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

  };

  outputs = {
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
  } @ inputs: let
    inherit (self) outputs;
    lib = nixpkgs.lib;
    systems = ["x86_64-linux"];
    forAllSystems = lib.genAttrs systems;
    # Overlay orchestrator + module auto-discovery
    flakeModules = import ./plumbing {inherit inputs;};
  in {
    # Grafts that add new packages, accessible via 'nix build .#pkgname'.
    # Overrides (grafts using 'prev') are excluded — they apply via the overlay
    # but forcing them here would fail if the upstream pkg doesn't exist in nixpkgs.
    packages = forAllSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = flakeModules.all;
          config.allowUnfree = true;
        };
        graftsDir = ./grafts;
        # Additions: graft files that don't take 'prev' (i.e. not overrides of existing pkgs)
        additionNames = map (lib.removeSuffix ".nix")
          (builtins.filter (n:
            lib.hasSuffix ".nix" n
            && n != "vim-plugins.nix"
            && !(builtins.functionArgs (import (graftsDir + "/${n}")) ? prev)
          ) (builtins.attrNames (builtins.readDir graftsDir)));
      in
        lib.filterAttrs (_: lib.isDerivation)
          (lib.listToAttrs (map (n: {name = n; value = pkgs.${n} or null;}) additionNames)));

    # Overlays — single source of truth for nixpkgs.overlays in all configs
    # outputs.overlays.all is consumed by config/nixos/base.nix and config/home/home.nix
    overlays = flakeModules;

    nixosConfigurations = {
      splinter = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules =
          [
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
        specialArgs = {inherit inputs outputs;};
        modules =
          [
            nur.modules.nixos.default
            nix-index-database.nixosModules.nix-index
            ./config/nixos/base.nix
            ./machines/bebop.nix
          ]
          ++ flakeModules.nixos-modules;
      };
      rocksteady = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules =
          [
            simple-nixos-mailserver.nixosModules.mailserver
            nix-index-database.nixosModules.nix-index
            ./config/nixos/base.nix
            ./machines/rocksteady.nix
          ]
          ++ flakeModules.nixos-modules;
      };
    };

    homeConfigurations = {
      "gurkan@bebop" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = {
          inherit inputs outputs;
          # Home-manager is not passing this for some reason?
          osConfig = self.nixosConfigurations.bebop.config;
        };
        modules =
          [
            nur.modules.homeManager.default
            ./config/home/home.nix
          ]
          ++ flakeModules.hm-modules; # grafts/home/ modules auto-applied
      };
      "gurkan@splinter" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = {
          inherit inputs outputs;
          # Home-manager is not passing this for some reason?
          osConfig = self.nixosConfigurations.splinter.config;
        };
        modules =
          [
            nur.modules.homeManager.default
            ./config/home/home.nix
          ]
          ++ flakeModules.hm-modules;
      };
    };
  };
}
