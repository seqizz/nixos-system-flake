# Pi coding-agent extension: pi-web-access - web search, URL fetch, GitHub
# repo cloning, PDF/YouTube/video understanding for the model. Unlike the
# other pi-ext-* grafts, upstream ships real npm dependencies (undici,
# linkedom, unpdf, ...), so this one goes through buildNpmPackage instead of
# a plain file copy.
#
# Upstream's package-lock.json includes a full resolved tree for the
# @earendil-works/pi-* peerDependencies (marked "peer": true, pulled in only
# for upstream's own local typecheck/test runs) whose nested entries are
# missing "integrity", which crashes prefetch-npm-deps/fetchNpmDeps. Those
# peers are satisfied by pi itself at runtime (same reasoning as the omitted
# rpiv-i18n peer in pi-ext-ask-user-question.nix), so
# pi-ext-web-access/package-lock.json is a copy of upstream's lockfile with
# every "peer": true entry stripped before hashing/fetching.
{
  final,
  inputs,
  ...
}:
let
  src = inputs.pi-web-access-src;
in
final.buildNpmPackage {
  pname = "pi-ext-web-access";
  version = "0.27.0";
  inherit src;

  postPatch = ''
    cp ${./pi-ext-web-access/package-lock.json} package-lock.json
  '';
  npmDepsHash = "sha256-oaOKm4RZoxXdwMTAAqmJoQzf6JiVeaNnar4ZlJ3+WNU=";

  # The pruned lockfile has no entries for the @earendil-works/pi-* peerDeps
  # (satisfied by pi itself, see top comment). Without this, npm ci still
  # tries to resolve+fetch them live to compute the peer set, which fails
  # offline (npmConfigHook's cache is fetch-once, only-if-cached).
  npmFlags = [
    "--legacy-peer-deps"
    "--omit=dev"
  ];

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -R . $out/
    runHook postInstall
  '';
}
