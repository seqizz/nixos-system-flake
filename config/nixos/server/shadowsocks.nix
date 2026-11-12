{
  lib,
  config,
  pkgs,
  ...
}:
let
  secrets = import ../secrets.nix;
  hardening = import ../helper-modules/service-hardening.nix;
  # shadowsocks-rust instead of the NixOS services.shadowsocks module: that one
  # wraps shadowsocks-libev, which is unmaintained and needs the EOL mbedtls 2.x.
  # Only AEAD ciphers are used, the old stream ciphers (aes-256-cfb) have no
  # integrity check and are trivially fingerprinted by active probing.
  # Clients must use the same method.
  ssConfig = pkgs.writeText "shadowsocks.json" (
    builtins.toJSON {
      server = "::";
      server_port = 5008;
      password = secrets.shadowsocksSecret;
      method = "chacha20-ietf-poly1305";
      mode = "tcp_and_udp";
    }
  );
in
{
  networking.firewall = {
    allowedTCPPorts = [
      5008
      12345
    ];
    allowedUDPPorts = [
      12345
    ];
  };

  systemd.services.shadowsocks-rust = {
    description = "shadowsocks-rust server";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = hardening // {
      ExecStart = "${pkgs.shadowsocks-rust}/bin/ssserver --config ${ssConfig}";
      DynamicUser = true;
      Restart = "always";
      RestartSec = 10;
      MemoryDenyWriteExecute = true;
    };
  };
}
