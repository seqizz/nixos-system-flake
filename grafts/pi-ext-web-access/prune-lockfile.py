#!/usr/bin/env python3
"""Generate the vendored package.json / package-lock.json for the pi-ext-web-access graft.

Upstream's package-lock.json cannot be fed to prefetch-npm-deps as-is: the
@earendil-works/pi-* packages (devDependencies used only for upstream's own
typecheck/test runs, also declared as peerDependencies that pi itself satisfies
at runtime) ship nested lockfile entries without "integrity", which crashes
prefetch-npm-deps. They also drag in a huge dev-only tree.

This script drops the @earendil-works/* packages from the manifest and prunes
the lockfile down to the entries actually reachable from the remaining
dependency set (npm's node_modules path resolution), so every surviving entry
is both integrity-carrying and required. The pruned pair is what the graft's
postPatch copies over the pristine source files.

Usage: prune-lockfile.py <upstream-source-dir> <output-dir>
"""

import json
import shutil
import sys
from pathlib import Path

# Names dropped from the manifest and never traversed. Satisfied by pi at runtime.
PRUNED_PACKAGES = ("@earendil-works/",)


def dep_edges(key, entry, is_root):
    """Names a lockfile entry needs resolved in the tree.

    Peers count as edges too: npm 7+ auto-installs them and upstream's lockfile
    carries them as real entries (e.g. express/hono/ws/zod under
    @modelcontextprotocol/sdk). Root devDependencies are needed for lockfile
    sync validation even though the build passes --omit=dev.
    """
    fields = ["dependencies", "optionalDependencies", "peerDependencies"]
    if is_root:
        fields.append("devDependencies")
    names = set()
    for field in fields:
        names.update(entry.get(field, {}))
    return names


def parent_dir(key):
    """Parent package directory of a lockfile key ("node_modules/a" -> "")."""
    parts = key.split("/") if key else []
    # Cutting at the last "node_modules" drops the trailing package dir
    # (2 segments for scoped names) in one step.
    for i in range(len(parts) - 1, -1, -1):
        if parts[i] == "node_modules":
            return "/".join(parts[:i])
    return None


def resolve(from_key, name, packages):
    """npm resolution: walk up node_modules nesting until the name is found."""
    directory = from_key
    while directory is not None:
        prefix = f"{directory}/" if directory else ""
        candidate = f"{prefix}node_modules/{name}"
        if candidate in packages:
            return candidate
        directory = parent_dir(directory)
    return None


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    src_dir, out_dir = Path(sys.argv[1]), Path(sys.argv[2])
    out_dir.mkdir(parents=True, exist_ok=True)

    manifest = json.loads((src_dir / "package.json").read_text())
    lockfile = json.loads((src_dir / "package-lock.json").read_text())
    packages = lockfile["packages"]

    # Prune the manifest: same set of names the lockfile tree drops.
    for field in ("dependencies", "devDependencies", "peerDependencies"):
        if field in manifest:
            manifest[field] = {
                name: spec
                for name, spec in manifest[field].items()
                if not name.startswith(PRUNED_PACKAGES)
            }
            if not manifest[field]:
                del manifest[field]

    # Reachability from the root entry over npm's node_modules resolution.
    reachable = set()
    queue = [""]
    while queue:
        key = queue.pop()
        if key in reachable:
            continue
        reachable.add(key)
        entry = packages[key]
        for name in dep_edges(key, entry, key == ""):
            if name.startswith(PRUNED_PACKAGES):
                continue
            target = resolve(key, name, packages)
            if target is not None and target not in reachable:
                queue.append(target)

    pruned = {
        key: entry for key, entry in packages.items() if key in reachable
    }
    # Keep the root entry in sync with the pruned manifest (npm validates it).
    root = pruned[""]
    for field in ("dependencies", "devDependencies", "peerDependencies"):
        if field in manifest:
            root[field] = manifest[field]
        else:
            root.pop(field, None)

    lockfile["packages"] = dict(sorted(pruned.items()))
    (out_dir / "package.json").write_text(json.dumps(manifest, indent=2) + "\n")
    (out_dir / "package-lock.json").write_text(json.dumps(lockfile, indent=2) + "\n")
    print(f"pruned {len(packages) - len(pruned)} of {len(packages)} lockfile entries")


if __name__ == "__main__":
    main()
