{
  final,
  inputs,
  ...
}:
final.python3Packages.callPackage ({
    lib,
    fetchFromGitHub,
    buildPythonPackage,
    netaddr,
    paramiko,
  }:
    buildPythonPackage rec {
      pname = "adminapi";
      version = "unstable-2026-04-04";
      format = "setuptools";

      src = inputs.serveradmin-src;
      propagatedBuildInputs = [netaddr paramiko];

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
