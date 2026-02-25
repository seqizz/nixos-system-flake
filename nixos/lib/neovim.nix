{
  pkgs,
  inputs,
  config,
  ...
}: let
  secrets = import ../lib/secrets.nix;
in {
  environment = {
    systemPackages = with pkgs; [
      fd # Needed for telescope
      nodejs # Not all plugins are well-integrated with nixpkgs
    ];
  };

  programs.neovim = {
    enable = true;
    vimAlias = true;
    defaultEditor = true;
    package = pkgs.neovim-unwrapped;
    withNodeJs = true;
    configure = {
      customRC = ''
        source ~/.config/nvim/nix.vim
      '';
      packages.myVimPackages = with pkgs.vimPlugins; {
        start =
          [
            # temporarily? disabled ones
            # context-vim # Keep the context on top, broke some stuff
            # tagbar # sidebar, superseded by aerial
            advanced-git-search-nvim # Search git history with telescope
            aerial-nvim # Code outline sidebar and navigation
            catppuccin-nvim # Modern, clean colorscheme
            coc-lua # Lua language support for CoC
            coc-nvim # Intellisense engine for Vim8 & Neovim
            coc-pyright # Python language support for CoC
            colorizer # Colorize hex codes
            conform-nvim # Autoformat for various languages
            diffview-nvim # Git diff viewing mode
            dressing-nvim # Better UI for input and select dialogs
            gitlinker-nvim # Create shareable file permalinks for Git hosts
            # gitsigns-nvim # Show git changes in the gutter
            (gitsigns-nvim.overrideAttrs (old: {
              version = "01-colorhint";
              src = pkgs.fetchFromGitHub {
                owner = "seqizz";
                repo = "gitsigns.nvim";
                rev = "g_colorhint";
                sha256 = "sha256-Rlh1E12s+BB8FW7eePgGKsNAAzJvjOosfxMI/y4c/ug=";
              };
            }))
            indent-blankline-nvim-lua # Visible indent lines
            indent-o-matic # Automatic indentation detection
            leap-nvim # Better movement with s
            limelight-vim # Focus helper
            lualine-nvim # Statusline
            neogit # Git integration
            nui-nvim # UI component library for Neovim
            nvim-cursorline # highlight word under cursor everywhere
            nvim-lspconfig # Native LSP configuration utility
            nvim-treesitter-context # Show code context while scrolling
            nvim-ts-context-commentstring # Better commenting for embedded languages
            plenary-nvim # Lua functions library used by many plugins
            splitjoin-vim # Better split/join with gS/gJ
            telescope-nvim # Highly extendable fuzzy finder
            telescope-zoxide # Zoxide integration for telescope
            terminus # terminal integration
            vim-fugitive # git helper
            vim-gutentags # Automatic tags management
            vim-markdown # Enhanced Markdown syntax and features
            vim-nix # Nix language syntax and filetype support
            vim-oscyank # Copy to system clipboard using ANSI OSC52
            vim-trailing-whitespace # Highlight and remove trailing whitespace
            vim-yaml # YAML syntax and filetype support
            vimwiki # Personal wiki and note-taking plugin
            yanky-nvim # Advanced yank and put functionality
            # Needed for commentnvim
            (nvim-treesitter.withPlugins (p: [
              p.bash
              p.css
              p.diff
              p.dockerfile
              p.gitcommit
              p.go
              p.ini
              p.json
              p.lua
              p.markdown
              p.nix
              p.puppet
              p.python
              p.ruby
              p.sql
              p.toml
              p.typst
              p.vim
              p.yaml
            ]))
          ]
          ++ (
            if config.networking.hostName == "splinter"
            then [
              # LLM, only needed on one host
              pkgs.unstable.vimPlugins.claude-code-nvim
            ]
            else []
          )
          ++ (with pkgs; [
            # These comes from flake + overlay
            # XXX: Move them above if they are available in nixpkgs
            coc-ruff # Ruff (Python linter) support for CoC
            commentnvim # Smart commenting plugin
            copilot # well, shit works
            # leap # Better movement with s
            smoothcursor # Smooth cursor movement animation
            telescope-file-browser # File browser extension for telescope
            trailblazer # Better mark jumps Ctrl-S and Shift-Up/Down
            undowarn # warn for over-undo
            vim-colorschemes-forked # Additional colorschemes collection
            vim-yadi # Yet Another Detect Indent plugin
            # yanky # Advanced yank and put functionality
          ]);
      };
    };
  };
}
#  vim: set ts=2 sw=2 tw=0 et :

