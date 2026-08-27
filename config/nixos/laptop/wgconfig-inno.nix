{
  config,
  pkgs,
  ...
}:
let
  primary_wg = import ../helper-modules/nm-wg-config.nix (
    {
      inherit pkgs;
    }
    // (import ../secrets.nix).generatedWG-Primary-opts
  );
  secondary_wg = import ../helper-modules/nm-wg-config.nix (
    {
      inherit pkgs;
    }
    // (import ../secrets.nix).generatedWG-Secondary-opts
  );
in
# This is pain in the ass. Someone needs to write a proper NetworkManager generator 😿
{
  imports = [ ../helper-modules/wg-routing.nix ];

  environment.etc = {
    "NetworkManager/system-connections/${primary_wg.name}.nmconnection" = {
      mode = "0600";
      text = primary_wg.wgConfig;
    };
    "NetworkManager/system-connections/${secondary_wg.name}.nmconnection" = {
      mode = "0600";
      text = secondary_wg.wgConfig;
    };
  };

  local.wireguardRouting.connections =
    map
      (wg: {
        inherit (wg) name endpoint;
        table = if wg.usePolicyRouting then wg.routeTableId else 0;
        mark = if wg.usePolicyRouting then wg.fwmarkId else 0;
        # ig.local is a DNSSEC island of trust, validated per-link only
        dnssec = true;
      })
      [
        primary_wg
        secondary_wg
      ];
}
#  vim: set ts=2 sw=2 tw=0 et :
