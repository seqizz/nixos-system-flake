{
  config,
  osConfig,
  ...
}: {
  imports =
    [
      ./packages.nix
      ./services.nix
      ./programs.nix
      ./variables.nix
      ./ssh.nix
      ./files.nix
      ./xserver.nix
      ./tarsnap.nix
    ]
    ++ (
      if osConfig.networking.hostName == "splinter"
      then [./inno.nix]
      else []
    );
}
