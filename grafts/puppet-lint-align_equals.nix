# Only the plugin files are installed, not a gem: openvox-lint runs under
# Bundler.setup, which hides every gem outside its own Gemfile.lock from
# puppet-lint's plugin discovery. grafts/openvox-lint-with-plugins.nix loads these files
# with --load instead.
{final, inputs, ...}:
final.stdenvNoCC.mkDerivation {
  pname = "puppet-lint-align_equals";
  version = "master";

  src = inputs.puppet-lint-align_equals-src;

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/puppet-lint
    cp -r lib/puppet-lint/plugins $out/lib/puppet-lint/
    runHook postInstall
  '';

  meta = with final.lib; {
    description = "puppet-lint check aligning parameter types, names and default value equals signs";
    homepage = "https://git.gurkan.in/gurkan/puppet-lint-align_equals";
    platforms = platforms.all;
  };
}
