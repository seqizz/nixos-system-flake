{pkgs, ...}:
{
  environment.systemPackages = with pkgs; [
    fd  # Needed for telescope
    nodejs  # Needed for Copilot/CoC
  ];

  programs.neovim = {
    enable = true;
    vimAlias = true;
    defaultEditor = true;
    package = pkgs.unstable.neovim-unwrapped;
    # package = pkgs.neovim-unwrapped;
    configure = {
      customRC = ''
        source ~/.config/nvim/nix.vim
      '';
      packages.myVimPackages = with pkgs.vimPlugins; {
        start = [
          catppuccin-nvim
          coc-lua
          coc-nvim
          coc-pyright
          colorizer # Colorize hex codes
          conform-nvim # Autoformat for various languages
          # context-vim # Keep the context on top
          gitlinker-nvim
          gitsigns-nvim # Show git changes in the gutter
          indent-blankline-nvim-lua # Visible indent lines
          indent-o-matic
          limelight-vim # Focus helper
          lualine-nvim # Statusline
          nvim-lspconfig
          pkgs.coc-ruff
          pkgs.commentnvim
          pkgs.copilot # well, shit works
          pkgs.leap # Better movement with s
          pkgs.telescope-file-browser
          pkgs.trailblazer # Better mark jumps Ctrl-S and Shift-Up/Down
          pkgs.undowarn # warn for over-undo
          pkgs.smoothcursor
          pkgs.vim-colorschemes-forked
          pkgs.vim-puppet-4tabs
          pkgs.vim-yadi
          pkgs.yanky
          splitjoin-vim # Better split/join with gS/gJ
          # tagbar # sidebar
          aerial-nvim # sidebar
          nvim-treesitter-context
          nvim-ts-context-commentstring
          telescope-nvim
          telescope-zoxide
          plenary-nvim # Needed by session-manager
          terminus # terminal integration
          vim-fugitive # git helper
          vim-gutentags
          nvim-cursorline # highlight word under cursor everywhere
          vim-markdown
          vim-nix
          vim-oscyank
          vim-trailing-whitespace
          vim-yaml
          vimwiki
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
