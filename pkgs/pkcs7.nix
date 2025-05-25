{
  lib,
  buildPythonPackage,
  fetchPypi,
}: let
  pname = "pkcs7";
  version = "0.1.2";
in
  buildPythonPackage {
    inherit pname version;

    src = fetchPypi {
      inherit pname version;
      extension = "zip";
      sha256 = "1zsy3i52vqriww5cp13z6si4m208f9dn0f86hj1cy134gm59k0xn";
    };

    meta = with lib; {
      description = "Controller for Tp-link Tapo P100 plugs, P105 plugs and L510E bulbs";
      homepage = "https://github.com/fishbigger/TapoP100";
      license = licenses.mit;
      maintainers = with maintainers; [seqizz];
    };
  }
