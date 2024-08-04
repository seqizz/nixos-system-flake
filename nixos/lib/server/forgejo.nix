{
  lib,
  config,
  pkgs,
  ...
}: {
  # MIGRATION
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
    # XXX: Need to stay on same gitea version until Forgejo 8 is released
    # https://codeberg.org/forgejo/forgejo/issues/3940
    package = pkgs.unstable.forgejo;
    # appName = "My git forks";
    # MIGRATION
    user = "gitea";
    group = "gitea";
    # stateDir = "/var/lib/gitea";
    stateDir = "/shared/forgejo";
    database = {
      name = "gitea";
      user = "gitea";
    };
    settings = {
      # MIGRATION
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
