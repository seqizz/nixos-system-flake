# Pi coding-agent extension: rpiv-ask-user-question, vendored as a
# self-contained store path so it runs both on the host AND inside llm-jail-pi
# without any npm/network at runtime. The QEMU guest shares /nix/store
# read-only, so this exact path resolves unchanged inside the VM.
#
# Layout mirrors node_modules resolution walk-up:
#   $out/index.ts                              extension entrypoint
#   $out/node_modules/@juicesharp/rpiv-config  sibling workspace dependency
#   $out/node_modules/typebox                  vendored from pi's own closure
# The optional @juicesharp/rpiv-i18n peer is intentionally absent; the
# extension degrades to English-only when it cannot dynamically import it.
{
  final,
  inputs,
  ...
}:
let
  src = inputs.rpiv-mono-src;
  # Same pi build llm-jail uses (its locked pi.nix rev), reached via the
  # transitive input so host and jail stay byte-identical without a second pin.
  pi = inputs.llm-jail.inputs.pi-nix.packages.${final.stdenv.hostPlatform.system}.default;
in
final.runCommandLocal "pi-ext-rpiv-ask-user-question-2.1.0" { } ''
  mkdir -p $out/node_modules/@juicesharp
  cp -R ${src}/packages/rpiv-ask-user-question/. $out/
  cp -R ${src}/packages/rpiv-config $out/node_modules/@juicesharp/rpiv-config
  # typebox ships inside pi but is not guaranteed visible to external
  # extension files, so vendor the same version pi uses.
  cp -R ${pi}/lib/node_modules/typebox $out/node_modules/typebox
''
