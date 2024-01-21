{ stdenv
, lib
, fetchurl
, intltool
, pkg-config
, file
, geany
, gtk3
, vte
, ctpl
, lua5_1
, gpgme
, libsoup
, enchant
, webkitgtk
}:

stdenv.mkDerivation rec {
  pname = "geany-plugins";
  version = "1.38";

  nativeBuildInputs = [
    intltool
    pkg-config
    file
    geany
    vte
    ctpl
  ];

  buildInputs = [
    gtk3
    lua5_1
    gpgme
    libsoup
    enchant
    webkitgtk
  ];

  src = fetchurl {
    url = "https://plugins.geany.org/geany-plugins/${pname}-${version}.tar.gz";
    sha256 = "06yc3cxl12whgxmqnlxi1halq8jsbxfah0s717jdc82jc1qdzpj4";
  };

  # The following plugins still require GTK2:
  # - devhelp
  # - geanypy
  # - multiterm
  # - webhelper
  # The following plugins contain a compile error:
  # - git-changebar (git version check)
  # - workbench
  # All other plugins should be built
  preConfigure = ''configureFlags="--with-geany-libdir=$out/lib"'';

  enableParallelBuilding = true;

  meta = with lib; {
    description = "Geany IDE plugins";
    longDescription = ''
      Plugins provided by the Geany Plugins Project. The built plugin libraries
      path needs to be manually linked or referenced by Geany for the plugins to
      be found (see the Plugins section of the Geany manual). 
    '';
    homepage = "https://plugins.geany.org/";
    license = licenses.gpl3Plus;
    platforms = platforms.all;
  };
}
