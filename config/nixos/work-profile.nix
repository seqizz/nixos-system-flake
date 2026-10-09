# Puts the work environment behind a NixOS specialisation instead of building it
# into the base system, for a machine that is only sometimes a work machine. The
# private profile then stays free of work certs and connection files.
#
# Opt in per machine with local.profiles.work.asSpecialisation = true. A machine
# that is permanently a work machine just sets local.profiles.work.enable = true
# and ignores this module entirely.
#
# Switching is runtime-only: the specialisation is built as part of every
# generation and already lives in the store, so work-on / work-off cost no
# rebuild and no reboot. A boot entry is generated as well.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.local.profiles.work;

  # switch-to-configuration of the child system, reachable only from the parent.
  childSwitch = "/run/current-system/specialisation/work/bin/switch-to-configuration";
  # The system profile keeps pointing at the parent generation even while the
  # specialisation is live, which is what makes the way back work.
  parentSwitch = "/nix/var/nix/profiles/system/bin/switch-to-configuration";

  nmcli = "${pkgs.networkmanager}/bin/nmcli";

  # Shared tail for both directions. switch-to-configuration only restarts units
  # whose *definition* changed, and the two profiles have an identical unit
  # graph — they differ only in files under /etc. So every daemon that reads
  # those files once at startup has to be poked by hand.
  resettle = ''
    # NM caches system-connections in memory: without this the work connections
    # linger after work-off and are absent after work-on.
    sudo ${nmcli} connection reload

    # resolved parses /etc/dnssec-trust-anchors.d only at startup, so the
    # ig.local anchor appears (or disappears) for it only across a restart.
    sudo ${config.systemd.package}/bin/systemctl restart systemd-resolved

    # That restart wipes the per-link DNS overrides the dnscrypt dispatcher
    # installs (see laptop/dnscrypt.nix — this is the same post-rebuild gotcha).
    # Reapplying each connected physical link re-runs the dispatcher and
    # restores them.
    for dev in $(${nmcli} -t -f DEVICE,TYPE,STATE device \
      | ${pkgs.gawk}/bin/awk -F: '$3 == "connected" && ($2 == "wifi" || $2 == "ethernet") { print $1 }'); do
      sudo ${nmcli} device reapply "$dev" || true
    done
  '';

  currentProfile = ''"$(cat /etc/nixos-profile 2>/dev/null || echo unknown)"'';
in
{
  config = lib.mkIf cfg.asSpecialisation {
    # NixOS empties `specialisation` inside children itself, so the child
    # inheriting this definition does not recurse.
    specialisation.work.configuration = {
      system.nixos.tags = [ "work" ];
      local.profiles.work.enable = true;
      environment.etc."nixos-profile".text = lib.mkForce "work\n";
    };

    # Runtime marker for the commands below. Probing for one of the files the
    # work profile happens to install would work too, but this says what it
    # means. The child overrides it above.
    environment.etc."nixos-profile".text = "private\n";

    # Inherited by the specialisation as well, so work-off is available from
    # inside work mode.
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "work-check" ''
        echo "profile: $(cat /etc/nixos-profile 2>/dev/null || echo unknown)"
        echo "system:  $(readlink /run/current-system)"
      '')

      (pkgs.writeShellScriptBin "work-on" ''
        set -e
        if [ ${currentProfile} = "work" ]; then
          echo "Already in work profile."
          exit 0
        fi
        sudo ${childSwitch} switch
        ${resettle}
        echo
        echo "Work profile active."
        echo "  Restart Firefox/Chromium — a running browser read the CA store at"
        echo "  startup and cannot see the work CAs that just appeared."
        echo "  VPN is not brought up automatically: nmcli connection up IG-WG-1"
      '')

      (pkgs.writeShellScriptBin "work-off" ''
        set -e
        if [ ${currentProfile} = "private" ]; then
          echo "Already in private profile."
          exit 0
        fi
        sudo ${parentSwitch} switch
        ${resettle}
        echo
        echo "Private profile active. Work CAs and connections are gone from"
        echo "/etc; restart browsers if you want them to forget the CAs too."
      '')
    ];
  };
}
