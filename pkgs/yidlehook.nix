{
  lib,
  pkgs,
  inputs,
  callPackage,
  setuptools,
  buildPythonApplication,
  poetry-core,
}:
buildPythonApplication rec {
  pname = "yidlehook";
  version = "master";
  pyproject = true;

  src = inputs.yidlehook-src;

  nativeBuildInputs = [
    poetry-core
    setuptools
  ];

  propagatedBuildInputs = [
    pkgs.python3Packages.xlib
  ];

  meta = with lib; {
    description = "A poor drop-in replacement for xidlehook, written in Python";
    homepage = https://git.gurkan.in/gurkan/yidlehook;
    license = licenses.gpl3;
    maintainers = ["seqizz"];
    platforms = platforms.linux;
  };
}
