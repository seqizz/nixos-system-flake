# Pi coding-agent extension: pi-web-access - web search, URL fetch, GitHub
# repo cloning, PDF/YouTube/video understanding for the model. Unlike the
# other pi-ext-* grafts, upstream ships real npm dependencies (undici,
# linkedom, unpdf, ...), so this one goes through buildNpmPackage instead of
# a plain file copy.
#
# Upstream's package-lock.json cannot be fed to prefetch-npm-deps as-is: the
# @earendil-works/pi-* packages (devDependencies for upstream's own
# typecheck/test runs, also declared as peerDependencies that pi itself
# satisfies at runtime) carry nested lockfile entries without
# "integrity", which crashes prefetch-npm-deps. So pi-ext-web-access/package.json
# and pi-ext-web-access/package-lock.json are vendored pruned copies generated
# by pi-ext-web-access/prune-lockfile.py (drops the @earendil-works/* names and
# every entry only they need). Regenerate both whenever the pinned upstream
# version changes, then update `version` and `npmDepsHash`:
#
#   python3 grafts/pi-ext-web-access/prune-lockfile.py <upstream-src> grafts/pi-ext-web-access
#
# fetchNpmDeps runs the same postPatch, so the npm cache is prefetched from the
# pruned lockfile and stays consistent with what npmConfigHook validates.
{
  final,
  inputs,
  ...
}:
let
  src = inputs.pi-web-access-src;
  version = "0.31.0";
  # Version drift between this pin and the vendored pair above is the failure
  # mode this graft is most likely to hit again (e.g. after nix flake update):
  # npm ci silently re-resolves the difference and dies with a confusing
  # ENOTCACHED instead of naming the real problem. Warn loudly at eval instead.
  lockVersion = (builtins.fromJSON (builtins.readFile ./pi-ext-web-access/package-lock.json)).packages."".version;
in
final.lib.warnIf (lockVersion != version) ''
  pi-ext-web-access: vendored package-lock.json is for ${lockVersion} but the graft pins ${version}.
  Regenerate grafts/pi-ext-web-access/package.json and package-lock.json with prune-lockfile.py and update npmDepsHash.
'' (final.buildNpmPackage {
  pname = "pi-ext-web-access";
  inherit version;
  inherit src;

  # The vendored package.json is required too, not just the lockfile: npm ci
  # does not fail on manifest deps missing from the lockfile, it re-resolves
  # them live (packument fetch, impossible against the fetch-once offline
  # cache - ENOTCACHED). Both files must therefore agree on the dependency set.
  postPatch = ''
    cp ${./pi-ext-web-access/package.json} package.json
    cp ${./pi-ext-web-access/package-lock.json} package-lock.json
  '';

  # Rebuild once after regenerating the vendored files and paste the
  # "got: sha256-..." value from the hash-mismatch error here.
  npmDepsHash = "sha256-gXNPtxxjs+9g3S7e+0uJOtNNoiseT9C7kX8DuCg+7+E=";

  # The pruned lockfile keeps upstream's devDependencies entries (typescript,
  # esbuild) for manifest sync validation, but they must not land in $out.
  npmFlags = [ "--omit=dev" ];

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -R . $out/
    runHook postInstall
  '';
})
