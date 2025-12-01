{
  lib,
  fetchFromGitHub,
  buildPythonPackage,
  netaddr,
  paramiko,
}:
buildPythonPackage rec {
  pname = "adminapi";
  version = "unstable-2023-11-03";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "innogames";
    repo = "serveradmin";
    rev = "04350bdd9da4db02167d0dc225d01f58354a5124";
    sha256 = "01gbndrfw9sz8is4qzd2f54rrq6v6c9ab2dbns2l0f46imq6lfnx";
  };

  pythonPath = [
    netaddr
    paramiko
  ];

  propagatedBuildInputs = pythonPath;

  doInstallCheck = false;
  doCheck = false;

  meta = with lib; {
    description = "Central server database management system of InnoGames - client module";
    homepage = "https://github.com/innogames/serveradmin";
    license = licenses.mit;
    maintainers = ["gurkan.gur"];
    platforms = platforms.linux;
  };
}
