{ lib
, python3
, fetchFromGitHub
}:
python3.pkgs.buildPythonPackage {
  pname = "TapoP100";
  version = "unstable-2022-11-03";

  src = fetchFromGitHub {
    owner = "fishbigger";
    repo = "TapoP100";
    rev = "43f51a03ab7a647f81682f7b39ceb2afdd04d3a1";
    sha256 = "1fz0394djknzf0nalrn5gnrziv35ns2hbz0lsqp8ir973sif7jk8";
  };

  patchPhase = ''
    substituteInPlace setup.py \
      --replace 'requests==2.24.0' 'requests' \
      --replace 'pycryptodome==3.9.8' 'pycryptodome'
  '';

  propagatedBuildInputs = with python3.pkgs; [
    (callPackage ./pkcs7.nix {})
    pycryptodome
    requests
  ];

  meta = with lib; {
    description = "Controller for TP-Link Tapo devices including the P100, P105, P110 plugs and the L530 and L510E bulbs";
    homepage    = "https://github.com/fishbigger/TapoP100";
    license     = licenses.mit;
    maintainers =  with maintainers; [ seqizz ];
  };
}

