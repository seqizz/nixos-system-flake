{
  final,
  prev,
  ...
}:
let
  # First nginx release carrying the security fix this graft exists for.
  fixedVersion = "1.30.7";
  channelHasFix = prev.lib.versionAtLeast prev.nginxStable.version fixedVersion;
in
prev.lib.warnIf channelHasFix
  ''
    nginxStable >= ${fixedVersion} is now in the channel, grafts/nginxStable.nix can be removed.
  ''
  (
    if channelHasFix then
      prev.nginxStable
    else
      # Only the source side comes from the release branch head. Dependencies
      # stay on the channel, so they come from the binary cache and nginx is
      # the single local build.
      prev.nginxStable.overrideAttrs (_: {
        inherit (final.release.nginxStable) src version patches;
      })
  )
