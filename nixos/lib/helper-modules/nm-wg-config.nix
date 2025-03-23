{
  pkgs,
  visibleName,
  fileName,
  remote,
  privateKey,
  publicKey,
  preSharedKey ? null,
  allowedIps,
  ipv4Address,
  ipv6Address,
  dnsAddress ? null,
  dnsSearchAddress ? null,
  mtu ? null,
  fwmark ? null,
  routeTable ? null,
  routeMetric ? null,
}: let
  # Get a uniq id for each given network, needed by networkmanager
  uuid =
    (import ./get-uuid.nix {
      inherit pkgs;
      baseText = fileName;
    })
    .out;
in {
  wgConfig = ''
    [connection]
    id=${visibleName}
    uuid=${builtins.readFile (uuid + "/outFile")}
    type=wireguard
    autoconnect=false
    interface-name=${fileName}
    timestamp=1601638109

    [wireguard]
    ${if fwmark != null then "fwmark=${fwmark}" else ""}
    ${if mtu != null then "mtu=${mtu}" else ""}
    private-key=${privateKey}
    peer-routes=true

    [wireguard-peer.${publicKey}]
    endpoint=${remote}
    ${if preSharedKey != null then "preshared-key=${preSharedKey}" else ""}
    ${if preSharedKey != null then "preshared-key-flags=0" else ""}
    persistent-keepalive=10
    allowed-ips=${allowedIps}

    [ipv4]
    address1=${ipv4Address}
    ${if dnsSearchAddress != null then "dns-search=${dnsSearchAddress}" else ""}
    method=manual
    ${if routeTable != null then "route-table=${routeTable}" else ""}
    ${if routeMetric != null then "route-metric=${routeMetric}" else ""}

    [ipv6]
    addr-gen-mode=stable-privacy
    address1=${ipv6Address}
    ${if dnsAddress != null then "dns=${dnsAddress}" else ""}
    ${if dnsSearchAddress != null then "dns-search=${dnsSearchAddress}" else ""}
    method=manual
    ${if routeTable != null then "route-table=${routeTable}" else ""}
    ${if routeMetric != null then "route-metric=${routeMetric}" else ""}

    [proxy]
  '';
  name = fileName;
}
