{ stdenv
, lib
, buildPythonPackage
, fetchFromGitHub
, vmprof
, pyqt4
, isPyPy
, pkgs
}:

let
  # scons is needed but using it requires Python 2.7
  # Therefore we create a separate env for it.
  scons = pkgs.python27.withPackages(ps: [ pkgs.scons ]);
in buildPythonPackage rec {
  version = "unstable-2022-12-08";
  pname = "Nuitka";

  src = fetchFromGitHub {
    owner = "Nuitka";
    repo = "Nuitka";
    rev = "04be4e7dae93566d5cccee17d41e61c774ed67f8";
    sha256 = "113ls94m8yklbzsmv1li8wshjvh05q4m3fn22nl0yc88fqsqzymw";
  };

  checkInputs = [ vmprof pyqt4 ];
  nativeBuildInputs = [ scons ];

  postPatch = ''
    patchShebangs tests/run-tests
  '' + lib.optionalString stdenv.isLinux ''
    substituteInPlace nuitka/plugins/standard/ImplicitImports.py --replace 'locateDLL("uuid")' '"${pkgs.utillinux.out}/lib/libuuid.so"'
  '';

  # We do not want any wrappers here.
  postFixup = '''';

  checkPhase = ''
    tests/run-tests
  '';

  # Problem with a subprocess (parts)
  doCheck = false;

  # Requires CPython
  disabled = isPyPy;

  meta = with lib; {
    description = "Python compiler with full language support and CPython compatibility";
    license = licenses.asl20;
    homepage = "https://nuitka.net/";
  };

}
