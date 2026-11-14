# VM, successor of rocksteady. Installed with nixos-anywhere; disk layout and
# boot loader target come from shredder-disko.nix.
{
  lib,
  modulesPath,
  ...
}:
{
  networking.hostName = "shredder";

  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./shredder-disko.nix
    ../config/nixos/server/common.nix
  ];

  # (needed for flakes)
  nixpkgs.hostPlatform = "x86_64-linux";

  boot = {
    loader.grub.configurationLimit = 10;
    kernelModules = [ "tcp_bbr" ];
    kernel.sysctl = {
      "net.ipv4.tcp_congestion_control" = "bbr";
    };
  };

  # Small disk and it builds itself: let GC drop build-time dependencies
  # (rustc, cargo, sources) instead of pinning them for every live generation.
  nix.settings = {
    keep-outputs = false;
    keep-derivations = false;
  };

  # Migration standby: the stateful services stay masked until rocksteady's
  # data is copied over, so shredder neither creates fresh state next to it
  # (empty sqlite DBs with -wal/-shm, empty mailboxes) nor runs the bots
  # against the same telegram tokens as rocksteady (409 conflicts).
  # enable = false masks the unit (symlink to /dev/null) but keeps the module
  # enabled, so its users and groups still exist and rsync can map file
  # owners by name. Remove this block at cutover.
  systemd.services =
    lib.genAttrs
      [
        "bind"
        "blog-song-updater"
        "bllk-timezone-bot"
        "dovecot"
        "forgejo"
        "gotosocial"
        "kufur-bot"
        "postfix"
        "redis-rspamd"
        "remark-gurkanin"
        "remark-siktirin"
        "rspamd"
        "rustypaste"
        "yarr"
      ]
      # mkForce: the bot and remark42 units set enable = true explicitly.
      (_: {
        enable = lib.mkForce false;
      });

  # Receive-only while shredder joins the share with a fresh index: whatever
  # happens to its local copy (partial rsync, empty dir, permission errors)
  # is never announced to the other devices. Local differences show up as
  # "locally changed" in the GUI instead. Remove at cutover, together with
  # the migration standby block above.
  services.syncthing.settings.folders.mainrepo.type = "receiveonly";

  swapDevices = [
    {
      device = "/swapfile";
      size = 2048;
    }
  ];

  system.stateVersion = "26.05";
}
