{final, ...}:
final.callPackage ({stdenv, lib, fetchurl, intltool, pkg-config, file, geany, gtk3, vte, ctpl, lua5_1, gpgme, libsoup, enchant, webkitgtk}:
  stdenv.mkDerivation rec {
    pname = "geany-plugins";
    version = "1.38";

    nativeBuildInputs = [intltool pkg-config file geany vte ctpl];
    buildInputs = [gtk3 lua5_1 gpgme libsoup enchant webkitgtk];

    src = fetchurl {
      url = "https://plugins.geany.org/geany-plugins/${pname}-${version}.tar.gz";
      sha256 = "06yc3cxl12whgxmqnlxi1halq8jsbxfah0s717jdc82jc1qdzpj4";
    };

    preConfigure = ''configureFlags="--with-geany-libdir=$out/lib"'';
    enableParallelBuilding = true;

    meta = with lib; {
      description = "Geany IDE plugins";
      homepage = "https://plugins.geany.org/";
      license = licenses.gpl3Plus;
      platforms = platforms.all;
    };
  }) {}
