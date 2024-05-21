{
  pkgs,
  visibleName,
  fileName,
  remote,
  privateKey,
  publicKey,
  preSharedKey,
  allowedIps,
  ipv4Address,
  ipv6Address,
  dnsAddress,
  dnsSearchAddress,
  mtu ? "1280",
  fwmark ? "66",
  routeTable ? "42",
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
    fwmark=${fwmark}
    mtu=${mtu}
    private-key=${privateKey}

    [wireguard-peer.${publicKey}]
    endpoint=${remote}
    preshared-key=${preSharedKey}
    preshared-key-flags=0
    persistent-keepalive=10
    allowed-ips=${allowedIps}

    [ipv4]
    address1=${ipv4Address}
    dns-search=${dnsSearchAddress}
    method=manual
    route-table=${routeTable}

    [ipv6]
    addr-gen-mode=stable-privacy
    address1=${ipv6Address}
    dns=${dnsAddress}
    dns-search=${dnsSearchAddress}
    method=manual
    route-table=${routeTable}

    [proxy]
  '';
  name = fileName;
}
