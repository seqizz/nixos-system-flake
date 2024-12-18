{ pkgs, lib, config, ... }:
{
  environment.systemPackages = with pkgs; [
    btrfs-progs
  ];

  systemd.services."my-encrypted-folder" = {
    restartIfChanged = false;
    requiredBy = [ "shared.mount" ];
    before = [ "shared.mount" ];

    unitConfig = {
      ConditionPathExists = "/root/.decrypt-file";
    };

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "true";
      ExecStart = "${pkgs.cryptsetup}/bin/cryptsetup open /encrypted-file encVol -d /root/.decrypt-file";
      ExecStop = "${pkgs.cryptsetup}/bin/cryptsetup close encVol";
    };
  };

  # And now the depending services
  systemd.services = {
    "anayasa-bot".unitConfig.RequiresMountsFor = "/shared";
    "bind".unitConfig.RequiresMountsFor = "/shared";
    "bllk-timezone-bot".unitConfig.RequiresMountsFor = "/shared";
    "comar-bot".unitConfig.RequiresMountsFor = "/shared";
    "dns-rfc2136-conf".unitConfig.RequiresMountsFor = "/shared";
    "dovecot2".unitConfig.RequiresMountsFor = "/shared";
    "forgejo".unitConfig.RequiresMountsFor = "/shared";
    "forgejo-secrets".unitConfig.RequiresMountsFor = "/shared";
    "kufur-bot".unitConfig.RequiresMountsFor = "/shared";
    "mysql".unitConfig.RequiresMountsFor = "/shared";
    "nginx".unitConfig.RequiresMountsFor = "/shared";
    "opendkim".unitConfig.RequiresMountsFor = "/shared";
    "postfix".unitConfig.RequiresMountsFor = "/shared";
    "remark-gurkanin".unitConfig.RequiresMountsFor = "/shared";
    "remark-siktirin".unitConfig.RequiresMountsFor = "/shared";
    "rspamd".unitConfig.RequiresMountsFor = "/shared";
    "rustypaste".unitConfig.RequiresMountsFor = "/shared";
    "syncthing".unitConfig.RequiresMountsFor = "/shared";
    "yarr".unitConfig.RequiresMountsFor = "/shared";
    "acme-gurkan.in" = {
      unitConfig.RequiresMountsFor = "/shared";
      after = [
        "systemd-tmpfiles-setup.service"
        "my-encrypted-folder.service"
      ];
    };
    "acme-mail.gurkan.in" = {
      unitConfig.RequiresMountsFor = "/shared";
      after = [
        "systemd-tmpfiles-setup.service"
        "my-encrypted-folder.service"
      ];
    };
    "acme-siktir.in" = {
      unitConfig.RequiresMountsFor = "/shared";
      after = [
        "systemd-tmpfiles-setup.service"
        "my-encrypted-folder.service"
      ];
    };
  };

  fileSystems."/shared" = {
    # @Bug not working with encrypted "files" as block devices
    # encrypted = {
      # enable = true;
      # label = "encVol";
      # keyFile = "/root/.decrypt-file";
      # blkDev = "/encrypted-file";
    # };
    device = "/dev/mapper/encVol";
    fsType = "btrfs";
    options = ["noatime"];
  };
}
