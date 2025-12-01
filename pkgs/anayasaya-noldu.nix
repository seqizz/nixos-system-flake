{ lib
, inputs
, python3Packages
}:
python3Packages.buildPythonPackage rec {

  pname = "anayasaya-noldu";
  version = "master";

  src = inputs.anayasaya-noldu-src;

  propagatedBuildInputs = with python3Packages; [
    python-telegram-bot
  ];

  doInstallCheck = false;
  doCheck = false;

  meta = with lib; {
    description = "Biktiran sikko bahaneler";
    homepage = "https://github.com/seqizz/anayasaya-noldu";
    license = licenses.mit;
    maintainers = [ "seqizz" ] ;
    platforms = platforms.linux;
  };
}
