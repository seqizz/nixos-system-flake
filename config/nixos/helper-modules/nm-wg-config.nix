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
  ipv6Address ? null,
  v4dnsAddress ? null,
  v6dnsAddress ? null,
  dnsSearchAddress ? null,
  mtu ? null,
  fwmark ? null,
  routeTable ? null,
  routeMetric ? null,
  # Whether this tunnel gets its own routing table + fwmark + ip rule.
  # On by default: a peer often advertises the very prefix its own endpoint
  # lives in (InnoGames announces its public ranges in allowed-ips), and with
  # those routes in the main table the handshake packets would be routed into
  # the tunnel they are supposed to establish. Keeping them in a private table
  # plus marking the encapsulated packets breaks that loop.
  policyRouting ? true,
}:
let
  lib = pkgs.lib;

  hexDigits = "0123456789abcdef";
  # Index of a hex char = length of the part before it when splitting on it.
  hexCharToInt = c: lib.stringLength (lib.head (lib.splitString c hexDigits));
  hexToInt = s: lib.foldl' (acc: c: acc * 16 + hexCharToInt c) 0 (lib.stringToCharacters s);

  # Overrides from secrets.nix may be ints, "42" or "0x42".
  toIntFlexible =
    v:
    if builtins.isInt v then
      v
    else if lib.hasPrefix "0x" v then
      hexToInt (lib.removePrefix "0x" v)
    else
      lib.toInt v;

  # Derive a stable table id from the interface name so every tunnel lands in
  # its own table. Two concurrently active full tunnels sharing table 42 would
  # otherwise overwrite each other's routes and each other's ip rule.
  # Range 100-250 keeps clear of the reserved 253-255 and of low ids commonly
  # hand-assigned elsewhere.
  derivedTableId =
    100 + (lib.mod (hexToInt (builtins.substring 0 4 (builtins.hashString "sha256" fileName))) 151);

  tableId = if routeTable != null then toIntFlexible routeTable else derivedTableId;

  # One mark shared by every tunnel, unlike the tables. The mark only means
  # "this packet is already WireGuard-encapsulated, keep it in the main table".
  # With a per-tunnel mark, tunnel B's outer packets would fail to match tunnel
  # A's "not fwmark" rule and could be routed into tunnel A instead.
  markId = if fwmark != null then toIntFlexible fwmark else 66; # 0x42

  usePolicyRouting = policyRouting;

  # Get a uniq id for each given network, needed by networkmanager
  uuid =
    (import ./get-uuid.nix {
      inherit pkgs;
      baseText = fileName;
    }).out;
in
{
  wgConfig = ''
    [connection]
    id=${visibleName}
    uuid=${builtins.readFile (uuid + "/outFile")}
    type=wireguard
    autoconnect=false
    interface-name=${fileName}
    timestamp=1601638109

    [wireguard]
    ${if usePolicyRouting then "fwmark=${toString markId}" else ""}
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
    ${if usePolicyRouting then "route-table=${toString tableId}" else ""}
    ${if routeMetric != null then "route-metric=${routeMetric}" else ""}
    ${if v4dnsAddress != null then "dns=${v4dnsAddress}" else ""}

    ${
      if ipv6Address != null then
        ''
          [ipv6]
          addr-gen-mode=stable-privacy
          address1=${ipv6Address}
          ${if v6dnsAddress != null then "dns=${v6dnsAddress}" else ""}
          ${if dnsSearchAddress != null then "dns-search=${dnsSearchAddress}" else ""}
          method=manual
          ${if usePolicyRouting then "route-table=${toString tableId}" else ""}
          ${if routeMetric != null then "route-metric=${routeMetric}" else ""}
        ''
      else
        ""
    }

    [proxy]
  '';
  name = fileName;
  endpoint = remote;
  routeTableId = tableId;
  fwmarkId = markId;
  inherit usePolicyRouting;
}
