{
  lib,
  config,
  pkgs,
  ...
}: {
  # XXX: Switch to clean forgejo when I have time
  # Maybe create a migration script?
  services.gitea.enable = false;
  users.users.gitea = {
    home = "/var/lib/gitea";
    useDefaultShell = true;
    group = "gitea";
    isSystemUser = true;
  };
  users.groups.gitea = {};

  services.forgejo= {
    enable = true;
    package = pkgs.unstable.forgejo;
    user = "gitea";
    group = "gitea";
    stateDir = "/var/lib/gitea";
    database = {
      name = "gitea";
      user = "gitea";
    };
    settings = {
      DEFAULT.APP_NAME = "My git forks";
      service.DISABLE_REGISTRATION = true;
      log.LEVEL = "Warn";
      repository = {
        DEFAULT_REPO_UNITS = "repo.code,repo.releases";
        DEFAULT_BRANCH = "master";
      };
      server = {
        ROOT_URL = "https://git.gurkan.in";
        HTTP_ADDR = "127.0.0.1";
        DOMAIN = "git.gurkan.in";
        LANDING_PAGE = "explore";
      };
      ui = {
        SHOW_USER_EMAIL = false;
        DEFAULT_THEME = "gitea-dark";
      };
      "ui.meta" = {
        DESCRIPTION = "This is where I fork my stuff";
      };
      other = {
        SHOW_FOOTER_VERSION = false;
      };
    };
  };
}
