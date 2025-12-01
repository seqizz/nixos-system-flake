{
  lib,
  inputs,
  python3Packages,
}:
python3Packages.buildPythonPackage rec {
  pname = "kufur-generator";
  version = "master";

  src = inputs.kufur-generator-src;

  propagatedBuildInputs = with python3Packages; [
    python-telegram-bot
  ];

  doInstallCheck = false;
  doCheck = false;

  meta = with lib; {
    description = "Awesome swears";
    homepage = "https://github.com/seqizz/kufur-generator";
    license = licenses.mit;
    maintainers = ["seqizz"];
    platforms = platforms.linux;
  };
}
