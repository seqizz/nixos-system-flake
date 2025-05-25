{
  description = "mysystemflake 🕺";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # nixpkgs-previous.url = "github:nixos/nixpkgs/nixos-24.05";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nur.url = "github:nix-community/NUR";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-25.05";
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
      url = "github:yshui/picom/v12.5";
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

    slock-flexipatch-src = {
      url = "git+https://git.gurkan.in/gurkan/slock-flexipatch.git";
      flake = false;
    };

    loose-src = {
      url = "git+https://git.gurkan.in/gurkan/loose.git";
      # url = "git+https://git.gurkan.in/gurkan/loose.git?ref=g_debug1";
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
    vim-puppet-4tabs-src = {
      url = "git+https://git.gurkan.in/gurkan/vim-puppet.git";
      flake = false;
    };
    vim-yadi-src = {
      url = "github:timakro/vim-yadi";
      flake = false;
    };
    # yanky-src = {
      # url = "github:gbprod/yanky.nvim";
      # flake = false;
    # };
    leap-src = {
      url = "github:ggandor/leap.nvim";
      flake = false;
    };
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
    avante-nvim = {
      url = "github:vinnymeller/avante-nvim-nightly-flake/1a198dee9786747f7010d215129011cebf568445";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
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
    nix-index-database,
    simple-nixos-mailserver,
    # wezterm,
    ...
  } @ inputs: let
    inherit (self) outputs;
    systems = [
      "x86_64-linux"
    ];
    # This is a function that generates an attribute by calling a function you
    # pass to it, with each system as an argument
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    # Custom packages
    # Accessible through 'nix build', 'nix shell', etc
    packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});

    # Custom packages and modifications, exported as overlays
    overlays = import ./overlays {inherit inputs;};
    # Reusable nixos modules
    nixosModules = import ./modules/nixos;
    # Reusable home-manager modules
    homeManagerModules = import ./modules/home-manager;

    nixosConfigurations = {
      splinter = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          disko.nixosModules.disko
          # { disko.devices.disk.disk1.device = "/dev/nvme0n1"; }
          nur.modules.nixos.default
          nix-index-database.nixosModules.nix-index
          ./nixos/configuration.nix
          ./nixos/machines/splinter.nix
        ];
      };
      bebop = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          nur.modules.nixos.default
          nix-index-database.nixosModules.nix-index
          ./nixos/configuration.nix
          ./nixos/machines/bebop.nix
        ];
      };
      rocksteady = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          self.nixosModules.yarr
          simple-nixos-mailserver.nixosModules.mailserver
          nix-index-database.nixosModules.nix-index
          ./nixos/configuration.nix
          ./nixos/machines/rocksteady.nix
        ];
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
        modules = [
          nur.modules.homeManager.default
          ./home-manager/home.nix
        ];
      };
      "gurkan@splinter" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = {
          inherit inputs outputs;
          # Home-manager is not passing this for some reason?
          osConfig = self.nixosConfigurations.splinter.config;
        };
        modules = [
          nur.modules.homeManager.default
          ./home-manager/home.nix
        ];
      };
    };
  };
}
