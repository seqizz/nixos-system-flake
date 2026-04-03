# Requires: inputs.kufur-generator-src in flake.nix
{final, inputs, ...}:
final.python3Packages.callPackage ({lib, buildPythonPackage, python-telegram-bot}:
  buildPythonPackage rec {
    pname = "kufur-generator";
    version = "master";

    src = inputs.kufur-generator-src;

    propagatedBuildInputs = [python-telegram-bot];

    doInstallCheck = false;
    doCheck = false;

    meta = with lib; {
      description = "Awesome swears";
      homepage = "https://github.com/seqizz/kufur-generator";
      license = licenses.mit;
      maintainers = ["seqizz"];
      platforms = platforms.linux;
    };
  }) {}
