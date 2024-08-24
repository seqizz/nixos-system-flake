{ stdenv, lib, fetchurl, unzip }:

let
  name = "lineicons";
  version = "4.0";
  sha256 = "sha256-4vrZHSUoSC7LlwxSOfz5w+h7ygg75enO8OvenJy2P/Y=";
in
stdenv.mkDerivation {

  inherit name;

  src = fetchurl {
    url = "https://cdn.lineicons.com/4.0/lineicons-4.0-basic-free.zip";
    inherit sha256;
  };

  buildInputs = [ unzip ];

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    cp "$src" icons.zip
    unzip icons.zip
    install -m444 -Dt $out/share/fonts/truetype web-font-files/fonts/lineicons.ttf
  '';

  meta = with lib; {
    description = "LineIcons - TTF Font";
    homepage = "http://lineicons.com/";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = with maintainers; [ seqizz ];
  };
}
