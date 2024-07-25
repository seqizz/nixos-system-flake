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
    banner = ''
    ,-.,-.,-.,-.
    `7        .'
     |        |
     |      .-!.     What? Sorry. I was using this time
     |  .---| ||      to think about something useful.
     | (C   `-'^.
     |  `      _;
     |        |
    ("`--.    |
    /`-._ `-._|        /\
   /     `-._/=\      /`-\
  /  /    \  >~7\     |`-|
 /  |      | \-\ ;   /\ /
;   `-j--f-'  \/`!__7\ y
|     |  |     `./_I_;'
|     |  |       ||
|     |  |       ||
|     |  |       ||
|     |  |_      ||
|____/   .-'_____|'
    (/|||\\ | |
     |`^' ` | \
     |      | |
     \      | |
     |      | |
     |      | /
     |      | |
     /      | |
     |______|_|
       |___|_|
      /     `=`=====.
      `='-----------'
'';
  };

  programs.mosh.enable=true;
}
