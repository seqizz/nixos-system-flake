{
  config,
  pkgs,
  ...
}: let
  secrets = import ../secrets.nix;
in {
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
    mailDirectory = "/shared/mail";
    dkim.keyDirectory = "/shared/.mail_dkim_keys";
    dkim.domains = {
      "gurkan.in".selectors."rsa-2026-06".keyFile = "/shared/.mail_dkim_keys/gurkan.in.rsa-2026-06.key";
      "siktir.in".selectors."rsa-2026-06".keyFile = "/shared/.mail_dkim_keys/siktir.in.rsa-2026-06.key";
    };
    x509.useACMEHost = "gurkan.in";
    loginAccounts = secrets.mailAccounts;
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
