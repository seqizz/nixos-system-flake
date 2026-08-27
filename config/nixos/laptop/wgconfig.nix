{
  config,
  pkgs,
  ...
}:
let
  truenas_wg = import ../helper-modules/nm-wg-config.nix (
    {
      inherit pkgs;
    }
    // (import ../secrets.nix)."generatedWG-truenas-${config.networking.hostName}-opts"
  );
in
{
  imports = [ ../helper-modules/wg-routing.nix ];

  environment.etc."NetworkManager/system-connections/${truenas_wg.name}.nmconnection" = {
    mode = "0600";
    text = truenas_wg.wgConfig;
  };

  local.wireguardRouting.connections = [
    {
      inherit (truenas_wg) name endpoint;
      table = if truenas_wg.usePolicyRouting then truenas_wg.routeTableId else 0;
      mark = if truenas_wg.usePolicyRouting then truenas_wg.fwmarkId else 0;
    }
  ];
}
#  vim: set ts=2 sw=2 tw=0 et :
