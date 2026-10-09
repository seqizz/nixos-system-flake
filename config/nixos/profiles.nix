# Declaration-only module for the local.profiles.* namespace.
#
# The options live here rather than next to their consumers because several
# modules read them (and one of them, neovim.nix, is a plain config-only module
# that cannot grow an `options` block without being reindented wholesale).
{ lib, ... }:
{
  options.local.profiles = {
    work.enable = lib.mkEnableOption ''
      work environment (CAs, office printers, VPN/WireGuard
      connections, ig.local DNSSEC anchor) and its Home Manager counterpart
    '';

    work.asSpecialisation = lib.mkEnableOption ''
      building the work environment as a NixOS specialisation rather than into
      the base system, for a machine that is only sometimes a work machine.
      Leaves work.enable off in the parent and on in the child, and adds the
      work-check / work-on / work-off commands. See work-profile.nix.
      A permanent work machine sets work.enable = true instead and leaves this
      alone
    '';

    llm.enable = lib.mkEnableOption ''
      LLM tooling, currently the neovim side of it. Off by default so headless
      machines do not drag it in
    '';
  };
}
