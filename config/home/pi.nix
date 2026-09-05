# Host pi coding-agent, managed declaratively via pi.nix's home-manager
# module. We use pi.nix's bun build (coding-agent-bun) rather than its npm
# build (the module default): the npm build gates on npmDepsHash, which goes
# stale whenever upstream pi bumps a transitive dep, while the bun2nix path
# has no such gate. grafts/llm-custody.nix overrides llm-custody's pi with the
# same package, so `pi` on the host and `llm-custody-pi` in the jail are
# byte-identical.
{
  pkgs,
  inputs,
  config,
  ...
}:
let
  # Load only index.ts and not the package's *.test.ts files
  askUserQuestion = "${pkgs.pi-ext-ask-user-question}/index.ts";
  bashConfirm = "${pkgs.pi-ext-bash-confirm}/bash-confirm.ts";
  webAccess = "${pkgs.pi-ext-web-access}/index.ts";
  todo = "${pkgs.pi-ext-todo}/index.ts";
  piPackage = inputs.pi-nix.packages.${pkgs.stdenv.hostPlatform.system}.coding-agent-bun;
in
{
  # The module wraps pi so every launch passes `--extension` and merges
  # `settings` into ~/.pi/agent/settings.json with jq at runtime. The file
  # stays writable, so pi's own /login and /settings edits survive.
  imports = [ inputs.pi-nix.homeModules.coding-agent ];

  programs.pi.coding-agent = {
    enable = true;
    package = piPackage;
    extensions = [ askUserQuestion bashConfirm webAccess todo ];
    settings = {
      # merged, not replaced: pi keeps managing the rest of settings.json
      defaultProjectTrust = "ask";
      bashConfirm = {
        enabled = true;
        safeCommands = [
          "^ls"
          "^cat"
          "^pwd"
          "^echo"
          "^head"
          "^tail"
          "^grep"
          "^rg"
          "^git (status|log|diff|branch|show)$"
          "^git (status|log|diff|branch|show) "
        ];
        blockedCommands = [
          "rm -rf"
          "sudo .* rm"
          ":>.*"
          "^dd "
          ": wq!"
          "mkfs"
        ];
        autoAccept = {
          enabled = false;
        };
      };
    };
  };

  # Link global instructions
  home.file.".pi/agent/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/syncfolder/dotfiles/CLAUDE.md";

  # Manifest read by launchers/pi.nix (llm-custody) to reflect the exact same
  # extension store paths into llm-custody-pi. Absolute /nix/store paths
  # resolve unchanged inside the sandbox (store bound read-only).
  home.file.".config/llm-custody/pi-extensions".text = ''
    ${askUserQuestion}
    ${bashConfirm}
    ${webAccess}
    ${todo}
  '';
}
