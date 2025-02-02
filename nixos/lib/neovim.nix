{
  pkgs,
  inputs,
  ...
}: let
  secrets = import ../lib/secrets.nix;
in {
  environment = {
    systemPackages = with pkgs; [
      fd # Needed for telescope
      nodejs # Needed for Copilot/CoC
    ];
    variables = {
      ANTHROPIC_API_KEY = secrets.ANTHROPIC_API_KEY; # Needed for Avante
    };
  };

  programs.neovim = {
    enable = true;
    vimAlias = true;
    defaultEditor = true;
    package = pkgs.unstable.neovim-unwrapped;
    # package = pkgs.neovim-unwrapped;
    withNodeJs = true;
    configure = {
      customRC = ''
        source ~/.config/nvim/nix.vim
      '';
      packages.myVimPackages = with pkgs.unstable.vimPlugins; {
        start = [
          neogit # Git integration
          inputs.avante-nvim.packages.${pkgs.system}.default # Custom Neovim configuration framework
          catppuccin-nvim # Modern, clean colorscheme
          dressing-nvim # Better UI for input and select dialogs
          plenary-nvim # Lua functions library used by many plugins
          nui-nvim # UI component library for Neovim
          coc-lua # Lua language support for CoC
          coc-nvim # Intellisense engine for Vim8 & Neovim
          coc-pyright # Python language support for CoC
          colorizer # Colorize hex codes
          conform-nvim # Autoformat for various languages
          # context-vim # Keep the context on top
          gitlinker-nvim # Create shareable file permalinks for Git hosts
          gitsigns-nvim # Show git changes in the gutter
          indent-blankline-nvim-lua # Visible indent lines
          indent-o-matic # Automatic indentation detection
          limelight-vim # Focus helper
          lualine-nvim # Statusline
          nvim-lspconfig # Native LSP configuration utility
          pkgs.coc-ruff # Ruff (Python linter) support for CoC
          pkgs.commentnvim # Smart commenting plugin
          pkgs.copilot # well, shit works
          pkgs.leap # Better movement with s
          pkgs.telescope-file-browser # File browser extension for telescope
          pkgs.trailblazer # Better mark jumps Ctrl-S and Shift-Up/Down
          pkgs.undowarn # warn for over-undo
          pkgs.smoothcursor # Smooth cursor movement animation
          pkgs.vim-colorschemes-forked # Additional colorschemes collection
          pkgs.vim-puppet-4tabs # Puppet syntax with 4-space tabs
          pkgs.vim-yadi # Yet Another Detect Indent plugin
          pkgs.yanky # Advanced yank and put functionality
          splitjoin-vim # Better split/join with gS/gJ
          # tagbar # sidebar
          aerial-nvim # Code outline sidebar and navigation
          nvim-treesitter-context # Show code context while scrolling
          nvim-ts-context-commentstring # Better commenting for embedded languages
          telescope-nvim # Highly extendable fuzzy finder
          telescope-zoxide # Zoxide integration for telescope
          plenary-nvim # Needed by session-manager
          terminus # terminal integration
          vim-fugitive # git helper
          vim-gutentags # Automatic tags management
          nvim-cursorline # highlight word under cursor everywhere
          vim-markdown # Enhanced Markdown syntax and features
          vim-nix # Nix language syntax and filetype support
          vim-oscyank # Copy to system clipboard using ANSI OSC52
          vim-trailing-whitespace # Highlight and remove trailing whitespace
          vim-yaml # YAML syntax and filetype support
          vimwiki # Personal wiki and note-taking plugin
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
        ];
      };
    };
  };
}
#  vim: set ts=2 sw=2 tw=0 et :

