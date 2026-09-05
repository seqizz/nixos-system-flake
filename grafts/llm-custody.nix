{
  final,
  inputs,
  ...
}:
let
  pkgs = inputs.llm-custody.packages.${final.stdenv.hostPlatform.system};
in
{
  # llm-custody defaults pi to its llm-agents.nix build; override with our pinned
  # pi.nix bun build so the jailed pi is byte-identical to the host pi (same
  # package feeds config/home/pi.nix). The bun build avoids the npm build's
  # stale-npmDepsHash breakage; pi.nix's makeWrapper self-sets PI_PACKAGE_DIR,
  # so llm-custody's launcher needs no extra env for this to run inside the jail.
  pi = pkgs.pi.override {
    pi-coding-agent = inputs.pi-nix.packages.${final.stdenv.hostPlatform.system}.coding-agent-bun;
  };
}
