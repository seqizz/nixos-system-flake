{rustPlatform, fetchFromGitHub, scdoc, installShellFiles}:

rustPlatform.buildRustPackage rec {
  name = "autorandr-rs";
  src = fetchFromGitHub {
    owner = "theotherjimmy";
    repo = "autorandr-rs";
    rev = "408764f2b42f4fea28e03a04f9826a8fee699086";
    sha256 = "1fxrkrvrilgjrbxwzk8b1xhhrjksd0lwvijz6gp7q22ny5yk2l5s";
  };
  cargoSha256 = "sha256-9OPWhbyg/tmc9xg/3dj+OtxVxoQ3tRDuF1yXi1jBAuY";
  nativeBuildInputs = [ scdoc installShellFiles ];
  preFixup = ''
    installManPage $releaseDir/build/${name}-*/out/${name}.1
    installManPage $releaseDir/build/${name}-*/out/${name}.5
  '';
}
