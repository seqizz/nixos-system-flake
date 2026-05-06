{ pkgs
, visibleName
, fileName
, remote
, ca
, cert
, key
, v4dnssearch
, v6dnssearch ? v4dnssearch
, ta
, pass ? ""
, cipher ? ""
}:
let
  # Get a uniq id for each given network, needed by networkmanager
  uuid = (import ./get-uuid.nix {
    inherit pkgs;
    baseText = fileName;
  }).out;
in
{
  # This is my preferred template, will extend later
  vpnConfig = ''
    [connection]
    id=${visibleName}
    uuid=${builtins.readFile (uuid + "/outFile")}
    type=vpn
    autoconnect=false
    permissions=
    timestamp=1601638109

    [vpn]
    ca=${ca}
    cert=${cert}
    cert-pass-flags=0
    ${if cipher != "" then "cipher=${cipher}" else ""}
    connection-type=tls
    dev=tun
    dev-type=tun
    key=${key}
    ping=3
    ping-restart=15
    remote=${remote}
    ta=${ta}
    ta-dir=1
    tunnel-mtu=1324
    service-type=org.freedesktop.NetworkManager.openvpn

    [vpn-secrets]
    cert-pass=${pass}

    [ipv4]
    dns-search=${v4dnssearch}
    method=auto
    never-default=true

    [ipv6]
    addr-gen-mode=stable-privacy
    dns-search=${v6dnssearch}
    ip6-privacy=0
    method=auto

    [proxy]
  '';
  name = fileName;
}
