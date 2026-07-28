# skillissue config, assembled from a collector option so host-specific repos
# live with their host module.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  yamlFormat = pkgs.formats.yaml { };
in
{
  options.local.skillissue.repos = lib.mkOption {
    type = lib.types.listOf (lib.types.attrsOf lib.types.anything);
    default = [ ];
    description = ''
      skillissue git repos to sync. Modules append entries here; the collected
      list is written verbatim to skillissue/config.yaml. Gating a repo to a
      host is done by contributing it from a host-specific module rather than a
      hostname check here.
    '';
  };

  config = {
    # Personal skills repo, available on every host.
    local.skillissue.repos = [
      {
        url = "ssh://gitea@git.gurkan.in/gurkan/llm-skills.git";
        writable = true;
      }
    ];

    xdg.configFile."skillissue/config.yaml".source = yamlFormat.generate "skillissue-config.yaml" {
      skill_paths = [ "~/.claude/skills" ];
      repos = config.local.skillissue.repos;
    };
  };
}
