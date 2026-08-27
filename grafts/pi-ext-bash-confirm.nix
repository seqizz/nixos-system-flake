# Pi coding-agent extension: pi-bash-confirm - confirm bash commands before
# execution with Telegram notification support. Vendored as a self-contained
# store path so it runs both on the host AND inside llm-jail-pi without any
# npm/network at runtime. The QEMU guest shares /nix/store read-only, so this
# exact path resolves unchanged inside the VM.
#
# Extension has no runtime dependencies (only devDependencies and peerDependencies
# satisfied by pi itself), so we only need the extension source files.
{
  final,
  inputs,
  ...
}:
let
  src = inputs.pi-bash-confirm-src;
in
final.runCommandLocal "pi-ext-bash-confirm-${src.rev or "unknown"}" { } ''
  mkdir -p $out
  cp -R ${src}/extensions/. $out/
  # Include package.json for version metadata (pi may read it)
  cp ${src}/package.json $out/
''
