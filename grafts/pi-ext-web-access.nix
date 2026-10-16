# Pi coding-agent extension: pi-web-access - web search, URL fetch, GitHub
# repo cloning, PDF/YouTube/video understanding for the model. Unlike the
# other pi-ext-* grafts, upstream ships real npm dependencies (undici,
# linkedom, unpdf, ...), so this one needs a real node_modules tree instead of
# a plain file copy.
#
# Upstream's package-lock.json cannot be fed to prefetch-npm-deps as-is: the
# @earendil-works/pi-* packages (devDependencies for upstream's own typecheck
# and test runs, also declared as peerDependencies that pi itself satisfies at
# runtime) carry nested lockfile entries with "resolved" but no "integrity",
# which crashes prefetch-npm-deps. The lockfile is therefore pruned down to the
# entries actually reachable from the runtime dependency set - below, at eval
# time, straight off the pinned source. Nothing is vendored into this repo and
# there is no dependency hash to refresh, so `nix flake update` is the whole
# upgrade procedure for this graft.
#
# importNpmLock (instead of buildNpmPackage's default fetchNpmDeps) is what
# makes that possible: it takes `package` and `packageLock` as plain attrsets
# and fetches every tarball as its own fixed-output derivation keyed by the
# lockfile's own integrity hash, so the pruning can happen in Nix and no
# aggregate npmDepsHash exists to go stale.
{
  final,
  inputs,
  ...
}:
let
  inherit (final) lib;
  src = inputs.pi-web-access-src;

  rawManifest = lib.importJSON "${src}/package.json";
  rawLock = lib.importJSON "${src}/package-lock.json";
  rawPackages = rawLock.packages;

  # Names pi provides to the extension at runtime. Dropped from the manifest
  # and never traversed, which also removes their whole nested dev-only tree
  # (that nested tree is the part missing "integrity").
  isPrunedName = name: lib.hasPrefix "@earendil-works/" name;

  # typebox is declared as a peerDependency upstream, but pi does not reliably
  # expose its own copy to external extension files (same reason the other
  # pi-ext-* grafts vendor it by hand), so surviving peers are promoted to
  # regular dependencies and land in node_modules. devDependencies are dropped
  # outright: nothing here is compiled, so typescript/esbuild would only be
  # fetch-and-discard weight.
  runtimeDeps = lib.filterAttrs (name: _: !isPrunedName name) (
    (rawManifest.dependencies or { }) // (rawManifest.peerDependencies or { })
  );

  # Parent package directory of a lockfile key, or null at the top:
  #   "node_modules/a/node_modules/b" -> "node_modules/a"
  #   "node_modules/@scope/a"         -> ""
  # Cutting at the last "node_modules" segment drops the trailing package
  # directory (two segments for a scoped name) in one step.
  parentDir =
    key:
    let
      parts = lib.splitString "/" key;
      lastNodeModules = lib.foldl' (
        acc: i: if lib.elemAt parts i == "node_modules" then i else acc
      ) null (lib.range 0 (lib.length parts - 1));
    in
    if lastNodeModules == null then null else lib.concatStringsSep "/" (lib.take lastNodeModules parts);

  # npm resolution: walk up the node_modules nesting until the name is found.
  resolveFrom =
    fromKey: name:
    let
      go =
        dir:
        if dir == null then
          null
        else
          let
            candidate = (if dir == "" then "" else "${dir}/") + "node_modules/${name}";
          in
          if rawPackages ? ${candidate} then candidate else go (parentDir dir);
    in
    go fromKey;

  # Root entry of the pruned tree. Peers are already folded into runtimeDeps,
  # so the walk below only needs to follow the three dependency fields npm
  # auto-installs (npm 7+ installs peers too, and upstream's lockfile carries
  # them as real entries, e.g. express/hono/ws/zod under
  # @modelcontextprotocol/sdk).
  rootEntry =
    (removeAttrs rawPackages."" [
      "devDependencies"
      "peerDependencies"
    ])
    // {
      dependencies = runtimeDeps;
    };

  edgeTargets =
    key:
    let
      entry = if key == "" then rootEntry else rawPackages.${key};
      names = lib.attrNames (
        (entry.dependencies or { })
        // (entry.optionalDependencies or { })
        // (entry.peerDependencies or { })
      );
    in
    lib.filter (target: target != null) (
      map (resolveFrom key) (lib.filter (name: !isPrunedName name) names)
    );

  reachable = lib.genAttrs (map (x: x.key) (
    builtins.genericClosure {
      startSet = [ { key = ""; } ];
      operator = { key }: map (target: { key = target; }) (edgeTargets key);
    }
  )) (_: true);

  prunedLock = rawLock // {
    packages = {
      "" = rootEntry;
    }
    // lib.mapAttrs (
      # "dev"/"peer" marked entries that survived the walk are real runtime
      # dependencies here (typebox), and npm would otherwise treat the lockfile
      # as out of sync with the rewritten manifest and try to re-resolve them
      # against a registry it cannot reach.
      _: entry:
      removeAttrs entry [
        "dev"
        "peer"
      ]
    ) (lib.filterAttrs (key: _: key != "" && reachable ? ${key}) rawPackages);
  };

  prunedManifest =
    (removeAttrs rawManifest [
      "devDependencies"
      "peerDependencies"
    ])
    // {
      dependencies = runtimeDeps;
    };

  # importNpmLock.importNpmLock, not .buildNodeModules. npmConfigHook copies
  # package.json/package-lock.json out of $npmDeps and runs npm offline against
  # them, so $npmDeps must be the *rewritten* pair whose "resolved" fields point
  # at Nix store paths. buildNodeModules is the nix-shell entry point: its $out
  # carries a prebuilt node_modules next to the unrewritten pair (registry
  # URLs), which sends npm to the network and fails with ENOTCACHED.
  npmSources = final.importNpmLock.importNpmLock {
    package = prunedManifest;
    packageLock = prunedLock;
  };
in
final.buildNpmPackage {
  pname = "pi-ext-web-access";
  inherit (rawManifest) version;
  inherit src;

  # Supplying npmDeps bypasses fetchNpmDeps (and its npmDepsHash) entirely.
  # The matching npmConfigHook is required: it installs the pruned
  # package.json/package-lock.json pair from $npmDeps over the pristine ones
  # before running npm offline, then restores the originals into $out.
  npmDeps = npmSources;
  inherit (final.importNpmLock) npmConfigHook;

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -R . $out/
    runHook postInstall
  '';
}
