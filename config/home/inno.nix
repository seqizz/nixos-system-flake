{
  config,
  pkgs,
  modulesPath,
  lib,
  ...
}:
let
  secrets = import ./secrets.nix { pkgs = pkgs; };
in
{
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
}
