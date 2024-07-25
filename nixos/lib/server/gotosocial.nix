{
  lib,
  config,
  ...
}: let
  secrets = import ../secrets.nix;
in {
  services.gotosocial = {
    enable = true;
    settings = {
      application-name = "dumpster fire";
      bind-address = "127.0.0.1";
      db-address = "/shared/gotosocial/database.sqlite";
      db-type = "sqlite";
      port = 6090;
      accounts-registration-open = false;
      instance-expose-public-timeline = true;
      protocol = "https";
      host = "has.siktir.in";
      smtp-host = "mail.gurkan.in";
      smtp-port = 587;
      smtp-username = secrets.socialMailAddress;
      smtp-from = secrets.socialMailAddress;
      smtp-password = secrets.socialMailPassword;
      storage-local-base-path = "/shared/gotosocial/storage";
      accounts-allow-custom-css = true;
      landing-page-user = "gurkan";
      media-emoji-local-max-size = "200KiB";
    };
  };
}
