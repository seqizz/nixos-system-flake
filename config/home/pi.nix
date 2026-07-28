# Host pi coding-agent, managed declaratively via pi.nix's home-manager
# module. The underlying pi package is llm-jail's locked pi.nix build (reached
# transitively in grafts/pi-ext-ask-user-question.nix and by the module's own
# default), so `pi` on the host and `llm-jail-pi` in the VM are the exact same build.
{
  pkgs,
  inputs,
  config,
  ...
}:
let
  # Load only index.ts and not the package's *.test.ts files
  askUserQuestion = "${pkgs.pi-ext-ask-user-question}/index.ts";
in
{
  # The module wraps pi so every launch passes `--extension` and merges
  # `settings` into ~/.pi/agent/settings.json with jq at runtime. The file
  # stays writable, so pi's own /login and /settings edits survive.
  imports = [ inputs.llm-jail.inputs.pi-nix.homeModules.coding-agent ];

  programs.pi.coding-agent = {
    enable = true;
    extensions = [ askUserQuestion ];
    settings = {
      # merged, not replaced: pi keeps managing the rest of settings.json
      defaultProjectTrust = "ask";
    };
  };

  # Link global instructions
  home.file.".pi/agent/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/syncfolder/dotfiles/CLAUDE.md";

  # Manifest read by the pijail() zsh wrapper to reflect the exact same
  # extension store paths into llm-jail-pi. Absolute /nix/store paths resolve
  # unchanged inside the guest (store shared read-only).
  home.file.".config/llm-jail/pi-extensions".text = askUserQuestion + "\n";
}
