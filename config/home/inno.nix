{
  config,
  osConfig,
  pkgs,
  lib,
  ...
}:
let
  secrets = import ./secrets.nix { pkgs = pkgs; };
  cfg = config.local.profiles.work;
in
{
  options.local.profiles.work.enable = lib.mkOption {
    type = lib.types.bool;
    default = osConfig.local.profiles.work.enable;
    description = ''
      Userland half of the work profile. Follows the NixOS option of
      the same name by default, which is what makes a specialisation switch move
      system and userland in one step.
    '';
  };

  config = lib.mkIf cfg.enable {
    xdg = {
      configFile = {
        "pip/pip.conf".text = secrets.pipConfigInno;
        "pypoetry/config.toml".text = secrets.poetryConfigInno;
        "pypoetry/auth.toml".text = secrets.poetryAuthInno;
      };
    };
    home = {
      file = {
        ".netrc".text = secrets.netrcInno;
      };
      packages = with pkgs; [
        pkgs.unstable.slack
      ];
    };

    # Work skills repo, append, collection is in skillissue.nix
    local.skillissue.repos = lib.mkBefore [
      {
        url = "git@gitlab.innogames.de:gurkan.gur/llm-skills.git";
        writable = true;
      }
    ];
  };
}
