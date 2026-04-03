# Requires: inputs.anayasaya-noldu-src in flake.nix (repo not public — add private git URL)
{final, inputs, ...}:
final.python3Packages.callPackage ({lib, buildPythonPackage, python-telegram-bot}:
  buildPythonPackage rec {
    pname = "anayasaya-noldu";
    version = "master";

    src = inputs.anayasaya-noldu-src;

    propagatedBuildInputs = [python-telegram-bot];

    doInstallCheck = false;
    doCheck = false;

    meta = with lib; {
      description = "Biktiran sikko bahaneler";
      homepage = "https://github.com/seqizz/anayasaya-noldu";
      license = licenses.mit;
      maintainers = ["seqizz"];
      platforms = platforms.linux;
    };
  }) {}
