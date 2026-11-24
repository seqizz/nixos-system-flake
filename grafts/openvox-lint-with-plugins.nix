# openvox-lint is a bundlerApp, so puppet-lint only discovers plugins from its
# own Gemfile.lock. Extra plugins are passed with --load on every invocation,
# which also covers editors calling puppet-lint from PATH.
#
# This is a separate attribute wrapping final.openvox-lint: an overlay after
# grafts-overlay (skyepkgs) defines openvox-lint and would replace a graft
# using that name.
{final, ...}: let
  plugins = [
    final.puppet-lint-stackenblocken
  ];
in
  final.symlinkJoin {
    name = "${final.openvox-lint.name}-with-plugins";
    paths = [final.openvox-lint];
    nativeBuildInputs = [final.makeWrapper];
    postBuild = ''
      loadFlags=()
      for plugin in ${final.lib.escapeShellArgs plugins}; do
        for check in "$plugin"/lib/puppet-lint/plugins/*.rb; do
          loadFlags+=(--add-flags "--load $check")
        done
      done
      wrapProgram $out/bin/puppet-lint "''${loadFlags[@]}"
    '';
    passthru.unwrapped = final.openvox-lint;
    inherit (final.openvox-lint) meta;
  }
