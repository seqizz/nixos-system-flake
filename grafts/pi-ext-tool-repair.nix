# Pi coding-agent extension: pi-tool-repair - validates and repairs malformed
# LLM tool calls (null fields, stringified arrays, wrong field names, anchor
# bleed) before the tool executes. Vendored as a self-contained store path so
# it runs both on the host AND inside llm-custody-pi without any npm/network
# at runtime. The sandbox shares /nix/store read-only, so this exact path
# resolves unchanged inside the jail.
#
# Layout mirrors node_modules resolution walk-up:
#   $out/tool-repair.ts            extension entrypoint (package.json "pi.extensions")
#   $out/src/                      imported by the entrypoint as ./src/index.js
#   $out/node_modules/typebox      vendored from pi's own closure
# The @earendil-works/pi-coding-agent peer is satisfied by pi itself at
# runtime, same as the other pi-ext-* grafts. __tests__/ and docs/ are left
# out; only what the extension loads at runtime is copied.
{
  final,
  inputs,
  ...
}:
let
  src = inputs.pi-tool-repair-src;
  # Same pi.nix bun build the host and jail use (pinned pi-nix input), so the
  # vendored typebox matches the pi runtime and host/jail stay byte-identical.
  pi = inputs.pi-nix.packages.${final.stdenv.hostPlatform.system}.coding-agent-bun;
in
final.runCommandLocal "pi-ext-tool-repair-0.2.5" { } ''
  mkdir -p $out/node_modules
  cp ${src}/tool-repair.ts $out/
  cp ${src}/package.json $out/
  cp -R ${src}/src $out/src
  # src/grammar-repair.ts does a value import of typebox/value, which ships
  # inside pi but is not guaranteed visible to external extension files.
  cp -R ${pi}/lib/node_modules/typebox $out/node_modules/typebox
''
