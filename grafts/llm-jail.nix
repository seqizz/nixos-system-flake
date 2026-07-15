{
  final,
  inputs,
  ...
}: let
  pkgs = inputs.llm-jail.packages.${final.stdenv.hostPlatform.system};
in {
  # Use system's nixpkgs claude-code instead of llm-jail's claude-code-nix input
  claude = pkgs.claude.override { claude-code = final.claude-code; };
  codex = pkgs.codex;
  copilot = pkgs.copilot;
  opencode = pkgs.opencode;
  shell = pkgs.shell;
}
