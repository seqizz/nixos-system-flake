{
  config,
  pkgs,
  ...
}: let
  truenas_wg = import ../helper-modules/nm-wg-config.nix ({
      inherit pkgs;
    }
    // (import ../secrets.nix)."generatedWG-truenas-${config.networking.hostName}-opts");
in {
  environment.etc."NetworkManager/system-connections/${truenas_wg.name}.nmconnection" = {
    mode = "0600";
    text = truenas_wg.wgConfig;
  };
}
#  vim: set ts=2 sw=2 tw=0 et :

