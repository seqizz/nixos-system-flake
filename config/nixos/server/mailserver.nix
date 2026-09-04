{
  config,
  pkgs,
  ...
}: let
  secrets = import ../secrets.nix;

  # Own runtime dir instead of /run/rspamd: that one is rspamd's
  # RuntimeDirectory and gets wiped when the service restarts.
  toggleDir = "/run/rspamd-greylist-toggle";
  toggleConf = "${toggleDir}/greylist-toggle.conf";
  toggleToken = "${toggleDir}/token";

  greylistToggle = pkgs.writeShellApplication {
    name = "mail-greylist-off";
    runtimeInputs = [pkgs.systemd pkgs.coreutils];
    text = ''
      duration="''${1:-5m}"
      token="$(date +%s%N)"

      install -d -m 0755 "${toggleDir}"
      printf 'enabled = false;\n' > "${toggleConf}"
      chmod 0644 "${toggleConf}"
      printf '%s\n' "$token" > "${toggleToken}"

      systemctl reload-or-restart rspamd.service

      # Token guards against an older timer re-enabling greylisting early
      # when the command is run again to extend the window.
      # $1 in the -c body must stay unexpanded here, the inner shell expands it.
      # shellcheck disable=SC2016
      #
      # systemd-run creates this as an independent transient unit via D-Bus,
      # it does NOT inherit this script's PATH (set above via runtimeInputs).
      # Bare `cat`/`rm`/`systemctl` are not on systemd's own default PATH on
      # NixOS (no /usr/bin, no /run/current-system/sw/bin), so every one of
      # them silently failed as "command not found": cat's failure made the
      # token compare empty-vs-token (never equal, so the file was never
      # cleaned up and rspamd never got re-enabled), and rm/systemctl would
      # have failed the same way had the compare ever passed.
      systemd-run \
        --collect \
        --unit="rspamd-greylist-enable-$token" \
        --on-active="$duration" \
        ${pkgs.runtimeShell} -c '
          if [ "$(${pkgs.coreutils}/bin/cat "${toggleToken}" 2>/dev/null || true)" = "$1" ]; then
            ${pkgs.coreutils}/bin/rm -f "${toggleConf}" "${toggleToken}"
            ${pkgs.systemd}/bin/systemctl reload-or-restart rspamd.service
          fi
        ' sh "$token"

      echo "Rspamd greylisting disabled for $duration"
    '';
  };

  greylistOn = pkgs.writeShellApplication {
    name = "mail-greylist-on";
    runtimeInputs = [pkgs.systemd pkgs.coreutils];
    text = ''
      if [ ! -e "${toggleConf}" ]; then
        echo "Rspamd greylisting already enabled"
        exit 0
      fi

      rm -f "${toggleConf}" "${toggleToken}"

      # Pending re-enable timers are already no-ops without the token file,
      # stopping them just avoids clutter in list-timers.
      systemctl stop 'rspamd-greylist-enable-*.timer' 2>/dev/null || true

      systemctl reload-or-restart rspamd.service
      echo "Rspamd greylisting re-enabled"
    '';
  };

  greylistStatus = pkgs.writeShellApplication {
    name = "mail-greylist-status";
    runtimeInputs = [pkgs.systemd pkgs.coreutils];
    text = ''
      if [ -e "${toggleConf}" ]; then
        echo "greylisting: DISABLED"
        systemctl list-timers --all 'rspamd-greylist-enable-*.timer'
      else
        echo "greylisting: enabled"
      fi
    '';
  };
in {
  environment.systemPackages = [greylistToggle greylistOn greylistStatus];

  # Mutable emergency override, normally absent. Disabling greylisting does
  # not release already-greylisted mail, it only stops the next retry from
  # being greylisted again.
  services.rspamd.locals."greylist.conf".text = ''
    .include(try=true,duplicate=merge) "${toggleConf}"
  '';

  # environment.systemPackages = with pkgs; [
  # rainloop-community
  # ];

  # My hosting company somehow got "abuse" mail because of this?
  services.rspamd.locals."rbl.conf".text = ''
  rbls {
    nixspam {
        enabled = false;
    }
  }
  '';

  mailserver = {
    enable = true;
    stateVersion = 5;
    fqdn = "mail.gurkan.in";
    domains = ["gurkan.in" "siktir.in"];
    storage.path = "/shared/mail";
    dkim.keyDirectory = "/shared/.mail_dkim_keys";
    dkim.domains = {
      "gurkan.in".selectors."rsa-2026-06".keyFile = "/shared/.mail_dkim_keys/gurkan.in.rsa-2026-06.key";
      "siktir.in".selectors."rsa-2026-06".keyFile = "/shared/.mail_dkim_keys/siktir.in.rsa-2026-06.key";
    };
    x509.useACMEHost = "gurkan.in";
    accounts = secrets.mailAccounts;
    enableImap = true;
    enablePop3 = false;
    enableImapSsl = true;
    enablePop3Ssl = false;
    enableManageSieve = true;
    virusScanning = false;
    localDnsResolver = false;
    # Just reject those spoofers of known domains, will increase the list later
    # XXX: this is migrated to rspamd, should be automatic, wipe later if spam-wise ok
    # policydSPFExtraConfig = ''
      # Reject_Not_Pass_Domains = live.com,aol.com,hotmail.com,gmail.com,yahoo.com
    # '';
    rejectRecipients = secrets.mailRejectRecipients;
    mailboxes = {
      Trash = {
        auto = "no";
        special_use = "\\Trash";
      };
      Junk = {
        auto = "subscribe";
        special_use = "\\Junk";
      };
      Drafts = {
        auto = "subscribe";
        special_use = "\\Drafts";
      };
      Sent = {
        auto = "subscribe";
        special_use = "\\Sent";
      };
      Seen = {
        auto = "subscribe";
        special_use = "\\Archive";
      };
    };
  };
}

# Random references, if needed later:

# fullTextSearch = {
#   enable = true;
#   # index new email as they arrive
#   autoIndex = true;
#   enforced = "body";
# };

# postfix = {
#   dnsBlacklists = [
#     "all.s5h.net"
#     "b.barracudacentral.org"
#     "bl.spamcop.net"
#     "blacklist.woody.ch"
#   ];
#
#   dnsBlacklistOverrides = ''
#     ${rdomain} OK
#     ${config.mailserver.fqdn} OK
#     127.0.0.0/8 OK
#     10.0.0.0/8 OK
#     192.168.0.0/16 OK
#   '';
#
#   config.smtp_hello_name = config.mailserver.fqdn;
# };
