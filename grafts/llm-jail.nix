{
  final,
  inputs,
  ...
}: let
  pkgs = inputs.llm-jail.packages.${final.stdenv.hostPlatform.system};
in {
  claude = pkgs.claude;
  codex = pkgs.codex;
  copilot = pkgs.copilot;
  shell = pkgs.shell;
}
