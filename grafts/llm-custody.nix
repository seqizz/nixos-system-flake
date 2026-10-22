{
  final,
  inputs,
  ...
}:
let
  pkgs = inputs.llm-custody.packages.${final.stdenv.hostPlatform.system};
in
# Everything upstream exposes, with the two tool runners replaced below. The
# merge rather than an explicit key list because this flake also ships
# host-side helpers that need no override at all (llm-custody-sync,
# llm-custody-toolbox) - naming them one by one means a new one is missing
# from pkgs.llm-custody until someone remembers to add it, and the symptom is
# an "attribute missing" error in config/home/packages.nix rather than
# anything pointing here.
pkgs
// {
  # llm-custody defaults pi to its llm-agents.nix build; override with our pinned
  # pi.nix bun build so the jailed pi is byte-identical to the host pi (same
  # package feeds config/home/pi.nix). The bun build avoids the npm build's
  # stale-npmDepsHash breakage; pi.nix's makeWrapper self-sets PI_PACKAGE_DIR,
  # so llm-custody's launcher needs no extra env for this to run inside the jail.
  pi = pkgs.pi.override {
    pi-coding-agent = inputs.pi-nix.packages.${final.stdenv.hostPlatform.system}.coding-agent-bun;
  };

  # Same reasoning for claude: llm-custody defaults it to llm-agents.nix's
  # own claude-code build, which is a second copy of a tool this flake
  # already installs from nixpkgs (config/home/packages.nix). Pointing the
  # jail at that same package keeps host `claude` and jailed
  # `llm-custody-claude` on one store path, so a version bump can't drift
  # between the two and nothing extra gets built or fetched.
  claude = pkgs.claude.override {
    claude-code = final.claude-code;
  };
}
