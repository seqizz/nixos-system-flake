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
          context-vim # Keep the context on top
          gitlinker-nvim
          gitsigns-nvim # Show git changes in the gutter
          indent-blankline-nvim-lua # Visible indent lines
          indent-o-matic
          limelight-vim # Focus helper
          lualine-nvim # Statusline
          pkgs.commentnvim
          pkgs.copilot # well, shit works
          pkgs.leap # Better movement with s
          pkgs.telescope-file-browser
          pkgs.trailblazer # Better mark jumps Ctrl-S and Shift-Up/Down
          pkgs.undowarn # warn for over-undo
          pkgs.vim-colorschemes-forked
          pkgs.vim-puppet-4tabs
          pkgs.vim-yadi
          pkgs.yanky
          splitjoin-vim # Better split/join with gS/gJ
          tagbar # sidebar
          telescope-nvim
          telescope-zoxide
          pkgs.neovim-project
          plenary-nvim # Needed by session-manager
          pkgs.neovim-session-manager # Needed by neovim-project
          terminus # terminal integration
          vim-fugitive # git helper
          vim-gutentags
          vim-illuminate # highlight word under cursor everywhere
          vim-markdown
          vim-nix
          vim-oscyank
          vim-trailing-whitespace
          vim-yaml
          vimwiki
          # Needed for commentnvim
          (nvim-treesitter.withPlugins (p: [
            p.bash
            p.dockerfile
            p.go
            p.json
            p.lua
            p.markdown
            p.nix
            p.python
            p.sql
            p.toml
            p.vim
            p.yaml
          ]))
        ];
      };
    };
  };
}
#  vim: set ts=2 sw=2 tw=0 et :
