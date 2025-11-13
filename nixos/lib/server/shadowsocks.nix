{
  lib,
  config,
  ...
}: let
  secrets = import ../secrets.nix;
in {
  networking.firewall = {
    allowedTCPPorts = [
      5008
      12345
    ];
    allowedUDPPorts = [
      12345
    ];
  };

  # TODO: shadowsocks 🙄
  nixpkgs.config.permittedInsecurePackages = [
    "mbedtls-2.28.10"
  ];

  services = {
    shadowsocks = {
      enable = true;
      encryptionMethod = "aes-256-cfb";
      password = secrets.shadowsocksSecret;
      port = 5008;
    };
  };
}
