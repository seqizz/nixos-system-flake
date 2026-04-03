{
  config,
  pkgs,
  ...
}: let
  primary_wg = import ../helper-modules/nm-wg-config.nix ({
      inherit pkgs;
    }
    // (import ../secrets.nix).generatedWG-Primary-opts);
  secondary_wg = import ../helper-modules/nm-wg-config.nix ({
      inherit pkgs;
    }
    // (import ../secrets.nix).generatedWG-Secondary-opts);
in
  # This is pain in the ass. Someone needs to write a proper NetworkManager generator 😿
  {
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
    networking.networkmanager.dispatcherScripts = [ {
      source = pkgs.writeText "wireguardRouteHelper" ''
        #!/usr/bin/env ${pkgs.bash}/bin/bash
        case "$CONNECTION_ID" in
            *Wireguard*)
                ;;
            *)
                exit
                ;;
        esac

        if [ "$NM_DISPATCHER_ACTION" = "up" ]; then
            # Route unmarked packets through table 42 (wg)
            ${pkgs.iproute2}/bin/ip -4 ru add prio 42 not fwmark 0x42 lookup 42
            ${pkgs.iproute2}/bin/ip -6 ru add prio 42 not fwmark 0x42 lookup 42
        fi


        if [ "$NM_DISPATCHER_ACTION" = "down" ]; then
            # Remove routing rule for table 42
            ${pkgs.iproute2}/bin/ip -4 ru del prio 42
            ${pkgs.iproute2}/bin/ip -6 ru del prio 42
        fi
      '';
      type = "basic";
    } ];
  }
#  vim: set ts=2 sw=2 tw=0 et :
