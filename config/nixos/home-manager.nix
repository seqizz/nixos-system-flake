# Home Manager runs as a NixOS module rather than a standalone profile.
#
# The reason is specialisations: a standalone homeConfiguration pins `osConfig`
# to the *parent* nixosConfiguration, so an option flipped inside
# `specialisation.<name>.configuration` is invisible to userland. As a NixOS
# module, HM is rebuilt as part of each specialisation and its `osConfig` is that
# specialisation's config, so one switch moves system and userland together.
{
  inputs,
  outputs,
  ...
}:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  # useUserPackages puts HM's packages in /etc/profiles/per-user/gurkan, which
  # is built with environment.pathsToLink. Without these two, the HM-managed
  # xdg.portal definitions and the desktop entries that come with HM packages
  # never get linked into the profile.
  environment.pathsToLink = [
    "/share/applications"
    "/share/xdg-desktop-portal"
  ];

  home-manager = {
    # Reuse the system nixpkgs (already carries outputs.overlays.all and
    # allowUnfree from base.nix) instead of instantiating a second one.
    useGlobalPkgs = true;
    # Packages land in /etc/profiles/per-user/gurkan, so they are part of the
    # system closure and get garbage-collected with the generation.
    useUserPackages = true;
    # First activation would otherwise abort on any pre-existing dotfile that HM
    # wants to own.
    backupFileExtension = "hm-bak";

    extraSpecialArgs = { inherit inputs outputs; };

    # NUR's home-manager module is deliberately absent: it only sets
    # nixpkgs.overlays, which useGlobalPkgs forbids. nur.modules.nixos.default
    # in flake.nix already applies that overlay to the system pkgs, and that is
    # the same instance HM gets, so pkgs.nur.repos.* works regardless.
    sharedModules = outputs.overlays.hm-modules; # grafts/home/ modules auto-applied

    users.gurkan = import ../home/home.nix;
  };
}
