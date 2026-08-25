{ inputs, pkgs, lib, ... }: {
  imports = [ inputs.nocruft.nixosModules.default ];

  # Prebuilt static release binary instead of the module's default, which builds
  # from source. Unlike a dynamic prebuilt this is not patchelf'd against the
  # local nixpkgs, so it cannot drift out of sync with it - the only way it goes
  # stale is by lagging behind upstream nocruft, which is a version bump, not a
  # build failure.
  #
  # mkDefault so a machine can still opt back into a source build by setting
  # programs.nocruft.package itself; the fallbacks upstream are
  # `.nocruft-static` (same thing, built here) and `.nocruft-dynamic`.
  programs.nocruft.package = lib.mkDefault
    inputs.nocruft.packages.${pkgs.stdenv.hostPlatform.system}.prebuilt;
}
