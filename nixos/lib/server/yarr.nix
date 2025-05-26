{
  lib,
  config,
  ...
}:
{
  services.yarr= {
    enable = true;
    port = 3636;
    environmentFile = /shared/yarr/envfile;
    authFilePath = /shared/.yarr-auth;
  };
}
