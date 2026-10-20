{ pkgs, lib, ... }:
let
  secrets = import ./secrets.nix { pkgs = pkgs; };

  # GHORG_TOKEN_CMD landed in ghorg 1.11.12; the stable channel is still behind,
  # so the token command below only works against unstable. Self-expiring per
  # the convention used by the version-pinning grafts: once stable catches up
  # the pin becomes a pointless second ghorg in the closure, so make it say so.
  tokenCmdVersion = "1.11.12";
  stableHasTokenCmd = lib.versionAtLeast pkgs.ghorg.version tokenCmdVersion;

  ghorg =
    lib.warnIf stableHasTokenCmd
      ''
        ghorg >= ${tokenCmdVersion} is now in stable nixpkgs, the pkgs.unstable
        pin in config/home/ghorg.nix can be dropped.
      ''
      (if stableHasTokenCmd then pkgs.ghorg else pkgs.unstable.ghorg);

  # ghorg runs GHORG_TOKEN_CMD and takes its stdout as the token, so no token
  # has to live in conf.yaml (a store symlink, world-readable) or in the
  # environment. glab already keeps a working token in its own config, this
  # only hands it over.
  ghorg-glab-token = pkgs.writeShellApplication {
    name = "ghorg-glab-token";

    runtimeInputs = [ pkgs.glab ];

    # writeShellApplication already prepends `set -euo pipefail`.
    text = ''
      host="''${GITLAB_HOST:-${secrets.ghorgGitlabHost}}"

      # glab writes its status report to stderr even on success, which would
      # show up on every ghorg run; swallow it and report failures ourselves.
      if ! glab auth status --hostname "$host" >/dev/null 2>&1; then
        echo "ghorg-glab-token: no valid glab session for $host," \
             "run: glab auth login --hostname $host" >&2
        exit 1
      fi

      token=$(glab config get token --host "$host")

      # An unknown key makes glab exit 0 with empty output, which ghorg would
      # otherwise pass on as an empty token and fail with a confusing 401.
      if [ -z "$token" ]; then
        echo "ghorg-glab-token: glab stores no token for $host" >&2
        exit 1
      fi

      # No trailing newline: ghorg puts this straight into the PRIVATE-TOKEN
      # header.
      printf '%s' "$token"
    '';
  };
in
{
  home.packages = [
    ghorg # Clone whole organizations from git remotes
    ghorg-glab-token
  ];

  xdg.configFile = {
    "ghorg/conf.yaml".source = ./config_files/ghorg;
    "ghorg/reclone.yaml".text = secrets.ghorgReclone;
  };
}
#  vim: set ts=2 sw=2 tw=0 et :
