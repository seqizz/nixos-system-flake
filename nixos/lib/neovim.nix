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
          lualine-nvim # Statusline
          coc-lua
          coc-nvim
          coc-pyright
          colorizer # Colorize hex codes
          context-vim # Keep the context on top
          conform-nvim # Autoformat for various languages
          pkgs.copilot # well, shit works
          indent-blankline-nvim-lua # Visible indent lines
          pkgs.leap # Better movement with s
          pkgs.trailblazer # Better mark jumps Ctrl-S and Shift-Up/Down
          limelight-vim # Focus helper
          pkgs.commentnvim
          pkgs.nvim-transparent
          splitjoin-vim # Better split/join with gS/gJ
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
          tagbar # sidebar
          telescope-nvim
          pkgs.telescope-file-browser
          telescope-zoxide
          terminus # terminal integration
          pkgs.undowarn # warn for over-undo
          pkgs.vim-colorschemes-forked
          vim-easytags
          vim-fugitive # git helper
          vim-gh-line
          vim-gutentags
          vim-illuminate # highlight word under cursor everywhere
          vim-markdown
          vim-nix
          vim-oscyank
          indent-o-matic
          pkgs.vim-puppet-4tabs
          vim-trailing-whitespace
          pkgs.vim-yadi
          vim-yaml
          vimwiki
          pkgs.yanky
        ];
      };
    };
  };
}
#  vim: set ts=2 sw=2 tw=0 et :
