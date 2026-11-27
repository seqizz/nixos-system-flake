# Puts the work environment behind a NixOS specialisation instead of building it
# into the base system, for a machine that is only sometimes a work machine. The
# private profile then stays free of work certs and connection files.
#
# Opt in per machine with local.profiles.work.asSpecialisation = true. A machine
# that is permanently a work machine just sets local.profiles.work.enable = true
# and ignores this module entirely.
#
# Switching is runtime-only: the specialisation is built as part of every
# generation and already lives in the store, so `sysman work on|off` costs no
# rebuild and no reboot (see sysman.nix and scripts/sysman). A boot entry is
# generated as well.
{
  config,
  lib,
  ...
}:
let
  cfg = config.local.profiles.work;
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

    # Runtime marker read by sysman and by awesome. Probing for one of the
    # files the work profile happens to install would work too, but this says
    # what it means. The child overrides it above.
    environment.etc."nixos-profile".text = "private\n";
  };
}
