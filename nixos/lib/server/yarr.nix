{
  lib,
  config,
  ...
}:
{
  services.yarr= {
    enable = true;
    port = 3636;
    directory = "/shared/yarr";
    authFilePath = "/shared/.yarr-auth";
  };
}
