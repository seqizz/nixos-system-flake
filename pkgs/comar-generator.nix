{ lib
, inputs
, python3Packages
}:
python3Packages.buildPythonPackage rec {

  pname = "comar-generator";
  version = "master";

  src = inputs.comar-generator-src;

  propagatedBuildInputs = with python3Packages; [
    python-telegram-bot
  ];

  doInstallCheck = false;
  doCheck = false;

  meta = with lib; {
    description = "Turkish right wing nonsense";
    homepage = "https://git.gurkan.in/gurkan/comar-generator.git";
    license = licenses.mit;
    maintainers = [ "seqizz" ] ;
    platforms = platforms.linux;
  };
}
