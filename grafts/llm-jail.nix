{
  final,
  inputs,
  ...
}:
let
  pkgs = inputs.llm-jail.packages.${final.stdenv.hostPlatform.system};
in
{
  # Use system's nixpkgs claude-code instead of llm-jail's claude-code-nix input
  claude = pkgs.claude.override { claude-code = final.claude-code; };
  # llm-jail defaults pi to its llm-agents.nix build; override with our pinned
  # pi.nix bun build so the jailed pi is byte-identical to the host pi (same
  # package feeds config/home/pi.nix). The bun build avoids the npm build's
  # stale-npmDepsHash breakage; pi.nix's makeWrapper self-sets PI_PACKAGE_DIR,
  # so llm-jail's launcher needs no extra env for this to run inside the guest.
  pi = pkgs.pi.override {
    pi-coding-agent = inputs.pi-nix.packages.${final.stdenv.hostPlatform.system}.coding-agent-bun;
  };
  codex = pkgs.codex;
  copilot = pkgs.copilot;
  opencode = pkgs.opencode;
  shell = pkgs.shell;
}
