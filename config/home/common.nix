{
  config,
  osConfig,
  ...
}:
{
  imports = [
    ./files.nix
    ./packages.nix
    ./pi.nix
    ./programs.nix
    ./services.nix
    ./skillissue.nix
    ./ssh.nix
    ./tarsnap.nix
    ./variables.nix
    ./xserver.nix
  ]
  ++ (if osConfig.networking.hostName == "splinter" then [ ./inno.nix ] else [ ]);
}
