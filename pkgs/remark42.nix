{ stdenv
, lib
, fetchurl
}:

stdenv.mkDerivation rec {
  name = "remark42-${version}";
  version = "1.14.0";

  src = fetchurl {
    url = "https://github.com/umputun/remark42/releases/download/v1.14.0/remark42.linux-amd64.tar.gz";
    sha256 = "0h5zrpzj4vqs7iqh19w0nap70p2dr32c5halc52nyga14y5p6xf2";
  };

  unpackPhase = ''
    tar xvf $src
  '';

  installPhase = ''
    install -m755 -D remark42.linux-amd64 $out/bin/remark42
  '';

  meta = with lib; {
    homepage = "https://remark42.com";
    description = "A comment engine";
    platforms = platforms.linux;
    maintainers = with maintainers; [ seqiz ];
  };
}
