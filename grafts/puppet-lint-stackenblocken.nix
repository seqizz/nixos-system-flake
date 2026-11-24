# Only the plugin files are installed, not a gem: openvox-lint runs under
# Bundler.setup, which hides every gem outside its own Gemfile.lock from
# puppet-lint's plugin discovery. grafts/openvox-lint-with-plugins.nix loads these files
# with --load instead.
{ final, inputs, ... }:
final.stdenvNoCC.mkDerivation {
  pname = "puppet-lint-stackenblocken";
  version = "master";

  src = inputs.puppet-lint-stackenblocken-src;

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/puppet-lint
    cp -r lib/puppet-lint/plugins $out/lib/puppet-lint/
    runHook postInstall
  '';

  meta = with final.lib; {
    description = "puppet-lint check formatting and aligning class and defined type parameters";
    homepage = "https://git.gurkan.in/gurkan/puppet-lint-stackenblocken";
    platforms = platforms.all;
  };
}
