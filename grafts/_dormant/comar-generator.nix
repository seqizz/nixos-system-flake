# Requires: inputs.comar-generator-src in flake.nix
{final, inputs, ...}:
final.python3Packages.callPackage ({lib, buildPythonPackage, python-telegram-bot}:
  buildPythonPackage rec {
    pname = "comar-generator";
    version = "master";

    src = inputs.comar-generator-src;

    propagatedBuildInputs = [python-telegram-bot];

    doInstallCheck = false;
    doCheck = false;

    meta = with lib; {
      description = "Turkish right wing nonsense";
      homepage = "https://git.gurkan.in/gurkan/comar-generator.git";
      license = licenses.mit;
      maintainers = ["seqizz"];
      platforms = platforms.linux;
    };
  }) {}
