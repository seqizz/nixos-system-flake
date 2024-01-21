{
  config,
  pkgs,
  ...
}:
let
  my_scripts = (import ../scripts.nix {pkgs = pkgs;});
in
{
  home.packages = with pkgs; [
    pkgs.unstable.slack
    # gnome3.gnome-keyring # needed for teams, thanks MS
    pkgs.unstable.discord
    my_scripts.innovpn-toggle
    thunderbird
    betterbird
  ];
}
