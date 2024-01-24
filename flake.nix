{
  description = "mysystemflake 🕺";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-2211.url = "github:nixos/nixpkgs/nixos-22.11";

    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nur.url = "github:nix-community/NUR";

    wezterm = {
      # url = "github:wez/wezterm?dir=nix";
      url = "github:davidsierradz/wezterm/add-additional-outputs-to-nix-flake?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    picom-src = {
      url = "github:yshui/picom";
    };

    greenclip-src = {
      url = "github:erebe/greenclip";
      flake = false;
    };

    awesomewm-src = {
      url = "github:awesomewm/awesome";
      flake = false;
    };

    loose-src = {
      url = "git+https://git.gurkan.in/gurkan/loose.git";
      flake = false;
    };

    nixos-plymouth-src = {
      url = "git+https://git.gurkan.in/gurkan/nixos-blur-plymouth.git";
      flake = false;
    };

    vimwiki-markdown-src = {
      url = "github:WnP/vimwiki_markdown";
      flake = false;
    };

    xidlehook-src = {
      url = "github:realSaltyFish/xidlehook";
    };

    # Vim plugins
    vim-puppet-4tabs-src = {
      url = "git+https://git.gurkan.in/gurkan/vim-puppet.git"; # plain https is not working?
      flake = false;
    };
    vim-yadi-src = {
      url = "github:timakro/vim-yadi";
      flake = false;
    };
    nvim-transparent-src = {
      url = "github:xiyaowong/nvim-transparent";
      flake = false;
    };
    yanky-src = {
      url = "github:gbprod/yanky.nvim";
      flake = false;
    };
    leap-src = {
      url = "github:ggandor/leap.nvim";
      flake = false;
    };
    trailblazer-src = {
      url = "github:LeonHeidelbach/trailblazer.nvim";
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
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nur,
    loose-src,
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
      innodellix = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          nur.nixosModules.nur
          ./nixos/configuration.nix
          ./nixos/machines/innodellix.nix
        ];
      };
    };

    homeConfigurations = {
      "gurkan@innodellix" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [
          nur.hmModules.nur
          ./home-manager/home.nix
          ./home-manager/lib/packages/workPackages.nix
        ];
      };
    };
  };
}
