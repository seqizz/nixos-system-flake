# Install dnsmagic library to /etc/dnsmagic for dispatcher and wrappers
{ config, pkgs, ... }:
{
  environment.etc."dnsmagic/dnsmagic-lib.sh".source = pkgs.writeText "dnsmagic-lib.sh" (
    builtins.readFile ../../config/home/config_files/dnsmagic-lib.sh
  );
}
