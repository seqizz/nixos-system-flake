{ config, pkgs, ... }:
let
  secrets = import ../secrets.nix;
  hardening = import ../helper-modules/service-hardening.nix;
in
{
  # remark42 writes the bolt DBs and, relative to WorkingDirectory, its
  # var/{pictures,avatars,backup} dirs, so it owns the whole comment-engine tree.
  users.users.remark42 = {
    isSystemUser = true;
    group = "remark42";
  };
  users.groups.remark42 = { };

  environment.systemPackages = with pkgs; [
    remark42
  ];

  # Systemd definitions
  systemd.services.remark-siktirin = {
    enable = true;
    wantedBy = [
      "multi-user.target"
    ];
    description = "Comment engine for siktir.in";
    environment = {
      SECRET = secrets.remarkSecret;
      REMARK_URL = "https://siktir.in/comments";
      # AUTH_ANON = "true"; # well done spammer mfers
      STORE_BOLT_PATH = "/shared/comment-engine/dbs";
      REMARK_PORT = "4381";
      SITE = "siktir.in";
      AUTH_GITHUB_CID = secrets.remarkGithubCidSiktirin;
      AUTH_GITHUB_CSEC = secrets.remarkGithubCsecSiktirin;
      ADMIN_SHARED_ID = secrets.remarkAdminSharedID;
      TELEGRAM_TOKEN = secrets.remarkTelegramTokenSiktirin;
      AUTH_TELEGRAM = "true";
      NOTIFY_ADMINS = "telegram";
      NOTIFY_TELEGRAM_CHAN = secrets.remarkTelegramChannel;
    };
    serviceConfig = hardening // {
      ExecStart = "${pkgs.remark42}/bin/remark42 server";
      User = "remark42";
      Group = "remark42";
      ReadWritePaths = [ "/shared/comment-engine" ];
      MemoryDenyWriteExecute = true;
      Restart = "always";
      RestartSec = 30;
      StandardOutput = "syslog";
      WorkingDirectory = "/shared/comment-engine/assets";
    };
  };
  systemd.services.remark-gurkanin = {
    enable = true;
    wantedBy = [
      "multi-user.target"
    ];
    description = "Comment engine for gurkan.in";
    environment = {
      SECRET = secrets.remarkSecret;
      REMARK_URL = "https://gurkan.in/comments";
      # AUTH_ANON = "true"; # well done spammer mfers
      STORE_BOLT_PATH = "/shared/comment-engine/dbs";
      REMARK_PORT = "4382";
      SITE = "gurkan.in";
      AUTH_GITHUB_CID = secrets.remarkGithubCidGurkanin;
      AUTH_GITHUB_CSEC = secrets.remarkGithubCsecGurkanin;
      AUTH_GOOGLE_CID = secrets.remarkGoogleCid;
      AUTH_GOOGLE_CSEC = secrets.remarkGoogleCsec;
      ADMIN_SHARED_ID = secrets.remarkAdminSharedID;
      TELEGRAM_TOKEN = secrets.remarkTelegramTokenGurkanin;
      AUTH_TELEGRAM = "true";
      NOTIFY_ADMINS = "telegram";
      NOTIFY_TELEGRAM_CHAN = secrets.remarkTelegramChannel;
    };
    serviceConfig = hardening // {
      ExecStart = "${pkgs.remark42}/bin/remark42 server";
      User = "remark42";
      Group = "remark42";
      ReadWritePaths = [ "/shared/comment-engine" ];
      MemoryDenyWriteExecute = true;
      Restart = "always";
      RestartSec = 30;
      StandardOutput = "syslog";
      WorkingDirectory = "/shared/comment-engine/assets";
    };
  };
}
