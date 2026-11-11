{
  final,
  inputs,
  ...
}:
let
  pkgs = inputs.llm-custody.packages.${final.stdenv.hostPlatform.system};

  # llm-custody defaults pi to its llm-agents.nix build; override with our pinned
  # pi.nix bun build so the jailed pi is byte-identical to the host pi (same
  # package feeds config/home/pi.nix). The bun build avoids the npm build's
  # stale-npmDepsHash breakage; pi.nix's makeWrapper self-sets PI_PACKAGE_DIR,
  # so llm-custody's launcher needs no extra env for this to run inside the jail.
  pi = pkgs.pi.override {
    pi-coding-agent = inputs.pi-nix.packages.${final.stdenv.hostPlatform.system}.coding-agent-bun;
  };

  # Same for claude
  claude = pkgs.claude.override {
    claude-code = final.unstable.claude-code;
  };

  # The `llm-custody` command resolves `launch <tool>` through a directory of
  # symlinks baked in at build time, so it has to be rebuilt on the overridden
  # runners - otherwise `llm-custody launch pi` would start upstream's pi while
  # `llm-custody-pi` on PATH starts ours.
  cli = pkgs.default.override {
    runners = { inherit pi claude; };
  };
in
# Everything upstream exposes, with the runners and the command over them
# replaced below. The merge rather than an explicit key list because upstream
# keeps exposing more than this flake overrides (another tool's runner, say) -
# naming them one by one means a new one is missing from pkgs.llm-custody until
# someone remembers to add it, and the symptom is an "attribute missing" error
# in config/home/packages.nix rather than anything pointing here.
pkgs
// {
  inherit pi claude;

  # One derivation under both names, the way upstream exposes it.
  default = cli;
  llm-custody = cli;
}
