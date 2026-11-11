{final, ...}:
# nixpkgs' cargo-setup-hook exports LIBGIT2_NO_VENDOR=1 for every rust package,
# but sheldon's derivation only passes openssl, so libgit2-sys finds no system
# libgit2 and aborts instead of falling back to the vendored copy.
# Drop once libgit2 is added to buildInputs upstream.
final.unstable.sheldon.overrideAttrs (old: {
  buildInputs = old.buildInputs ++ [final.unstable.libgit2];
})
