{
  config,
  pkgs,
  modulesPath,
  lib,
  ...
}: let
  secrets = import ./secrets.nix {pkgs = pkgs;};
in {
  xdg = {
    configFile = {
      "pip/pip.conf".text = secrets.pipConfigInno;
      "pypoetry/config.toml".text = secrets.poetryConfigInno;
      "pypoetry/auth.toml".text = secrets.poetryAuthInno;
    };
  };
}
