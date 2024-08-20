{
  config,
  pkgs,
  modulesPath,
  lib,
  ...
}: let
  secrets = import ./secrets.nix {pkgs = pkgs;};
  my_scripts = (import ./scripts.nix {pkgs = pkgs;});
in {
  xdg = {
    configFile = {
      "pip/pip.conf".text = secrets.pipConfigInno;
      "pypoetry/config.toml".text = secrets.poetryConfigInno;
      "pypoetry/auth.toml".text = secrets.poetryAuthInno;
    };
  };
  home.packages = with pkgs; [
    pkgs.unstable.slack
    my_scripts.innovpn-toggle
  ];
}
