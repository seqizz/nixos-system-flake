{
  lib,
  config,
  pkgs,
  ...
}:
let
  robotsTxt = pkgs.writeText "git-disallow-robots" ''
    #  ▗▄▄▄▖▗▖_▗▖_▗▄▄▖▗▖_▗▖_____▗▄▖_▗▄▄▄▖▗▄▄▄▖
    #  ▐▌___▐▌_▐▌▐▌___▐▌▗▞▘____▐▌_▐▌▐▌___▐▌___
    #  ▐▛▀▀▘▐▌_▐▌▐▌___▐▛▚▖_____▐▌_▐▌▐▛▀▀▘▐▛▀▀▘
    #  ▐▌___▝▚▄▞▘▝▚▄▄▖▐▌_▐▌____▝▚▄▞▘▐▌___▐▌___
    #  _______________________________________
    #  _______________________________________
    #  _______________________________________

    User-agent: *
    Disallow: /
  '';
in
{
  # XXX: Switch to clean forgejo when I have time
  # Maybe create a migration script?
  services.gitea.enable = false;
  users.users.gitea = {
    home = "/var/lib/gitea";
    useDefaultShell = true;
    group = "gitea";
    isSystemUser = true;
  };
  users.groups.gitea = { };

  services.forgejo = {
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
        DISABLE_DOWNLOAD_SOURCE_ARCHIVES = true;
      };
      # Only served over https (nginx), so the session cookie must carry the Secure flag
      session.COOKIE_SECURE = true;
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

  # Forgejo serves $customDir/public/robots.txt at /robots.txt. A package can
  # only ship files inside its store path, never under /var, so the store file
  # is linked in by tmpfiles. L+ replaces whatever is there, and tmpfiles
  # reapplies it on every boot, not only on switch.
  systemd.tmpfiles.rules =
    let
      cfg = config.services.forgejo;
    in
    [
      "d ${cfg.customDir}/public 0750 ${cfg.user} ${cfg.group} -"
      "L+ ${cfg.customDir}/public/robots.txt - - - - ${robotsTxt}"
    ];
}
