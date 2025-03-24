{
  config,
  pkgs,
  ...
}: let
  pihole_wg = import ../helper-modules/nm-wg-config.nix ({
      inherit pkgs;
    }
    // (import ../secrets.nix).generatedWG-pihole-opts);
in {
  environment.etc."NetworkManager/system-connections/${pihole_wg.name}.nmconnection" = {
    mode = "0600";
    text = pihole_wg.wgConfig;
  };
}
#  vim: set ts=2 sw=2 tw=0 et :

