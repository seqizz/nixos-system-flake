# Prebuilt release binary instead of the source build the passthrough overlay
# would otherwise pick (`packages.default`). trayplay is a GTK4 app, so building
# it costs ~10 minutes on every nixpkgs bump that touches its closure, and none
# of that is cached anywhere.
#
# The tarball's binary was linked against the *builder's* GTK stack and is
# autoPatchelf'd against this system's, so a large enough soname drift fails the
# build loudly ("could not satisfy dependency" from autoPatchelf) rather than
# producing something that breaks at runtime. Two ways out when that happens:
# cut a new trayplay release, or temporarily swap `.prebuilt` for `.trayplay`
# below (the same source build is also reachable as `pkgs.passthrough.trayplay`,
# which the passthrough overlay set before this graft ran).
{ final, inputs, ... }:
inputs.trayplay-src.packages.${final.stdenv.hostPlatform.system}.prebuilt
