{
  final,
  inputs,
  ...
}:
final.python3Packages.callPackage ({
    lib,
    fetchFromGitHub,
    buildPythonPackage,
    hatchling,
    netaddr,
    paramiko,
  }:
    buildPythonPackage rec {
      pname = "adminapi";
      version = "4.26.0";
      pyproject = true;

      src = inputs.serveradmin-src;
      # Repo migrated to uv workspace; adminapi now lives in packages/adminapi
      setSourceRoot = "sourceRoot=$(echo */packages/adminapi)";

      build-system = [hatchling];
      propagatedBuildInputs = [netaddr paramiko];

      # nixpkgs ships paramiko 4.x; upstream still pins <4
      pythonRelaxDeps = ["paramiko"];

      doInstallCheck = false;
      doCheck = false;

      meta = with lib; {
        description = "Central server database management system of InnoGames - client module";
        homepage = "https://github.com/innogames/serveradmin";
        license = licenses.mit;
        maintainers = ["gurkan.gur"];
        platforms = platforms.linux;
      };
    }) {}
