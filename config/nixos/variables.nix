{config, pkgs, ... }:
{
  environment.variables = {
    # TODO: Move all of these to their respective files

    # Required for wrapped neovim
    VIMWIKI_MARKDOWN_EXTENSIONS = ''{\"toc\": {\"baselevel\": 2 }}'';
    FZF_BASE = "${pkgs.fzf}/share/fzf";

    # Added for convenience
    FZF_DEFAULT_OPTS = "--reverse --border --height=60% --color='bg+:#6C71C4'";

    # Workaround for wezterm issue: https://github.com/wez/wezterm/issues/3610
    XKB_DEFAULT_LAYOUT = "tr";
    XKB_DEFAULT_VARIANT= "";

    DO_NOT_TRACK = "1";
  };
}
