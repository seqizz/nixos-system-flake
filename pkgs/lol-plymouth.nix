{ stdenv, inputs }:

stdenv.mkDerivation rec {
  name = "lol";
  version = "unstable-2022-07-08";

  src = inputs.lol-plymouth-src;

  buildInputs = [ stdenv ];

  configurePhase = ''
    install_path=$out/share/plymouth/themes
    mkdir -p $install_path
  '';

  installPhase = ''
    cp -r lol $install_path
  '';

  meta = with stdenv.lib; { platfotms = platforms.linux; };
}
