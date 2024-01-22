{ stdenv
, lib
, pkg-config
, autoreconfHook
, autoconf-archive
, guile
, texinfo
, rofi
, inputs
}:

stdenv.mkDerivation rec {
  pname = "pinentry-rofi";
  version = "unstable-2023-07-10";

  src = inputs.pinentry-rofi-src;

  nativeBuildInputs = [
    autoconf-archive
    autoreconfHook
    pkg-config
    texinfo
  ];

  buildInputs = [ guile ];

  propagatedBuildInputs = [ rofi ];

  meta = with lib; {
    description = "Rofi frontend to pinentry";
    homepage = "https://github.com/plattfot/pinentry-rofi";
    license = licenses.gpl3Plus;
    platforms = platforms.unix;
  };
}
