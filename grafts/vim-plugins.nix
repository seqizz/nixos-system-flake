# Neovim plugins built from flake inputs.
# Returns a set — each entry gets merged directly into pkgs.
# To add a plugin: add input to flake.nix + one line here.
{helpers, inputs, ...}: {
  vim-yadi = helpers.mkVimPlugin "vim-yadi" inputs.vim-yadi-src;
  trailblazer = helpers.mkVimPlugin "trailblazer" inputs.trailblazer-src;
  commentnvim = helpers.mkVimPlugin "commentnvim" inputs.commentnvim-src;
  telescope-file-browser = helpers.mkVimPlugin "telescope-file-browser" inputs.telescope-file-browser-src;
  coc-ruff = helpers.mkVimPlugin "coc-ruff" inputs.coc-ruff-src;
  vim-colorschemes-forked = helpers.mkVimPlugin "vim-colorschemes-forked" inputs.vim-colorschemes-forked-src;
  copilot = helpers.mkVimPlugin "copilot" inputs.copilot-src;
  undowarn = helpers.mkVimPlugin "undowarn" inputs.undowarn-src;
  smoothcursor = helpers.mkVimPlugin "smoothcursor" inputs.smoothcursor-src;
}
