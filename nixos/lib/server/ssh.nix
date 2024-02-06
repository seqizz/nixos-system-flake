{ lib, config, ... }:
let
  secrets = import ../secrets.nix;
in
{
  users.users.root = {
    openssh.authorizedKeys.keys = [
      secrets.innoSSHPub
      secrets.plutoSSHPub
      secrets.siktirinSSHPub
    ];
    # For emergencies
    hashedPassword = secrets.rocksteadyRootPass;
  };

  services.openssh = {
    enable = true;
    banner = builtins.readFile /shared/.sshd_banner;
  };
}
