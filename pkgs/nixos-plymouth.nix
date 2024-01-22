{ stdenv, inputs }:

stdenv.mkDerivation rec {
  name = "nixos-blur";
  version = "unstable-2022-07-08";

  src = inputs.nixos-plymouth-src;

  buildInputs = [ stdenv ];

  configurePhase = ''
    install_path=$out/share/plymouth/themes
    mkdir -p $install_path
  '';

  installPhase = ''
    cp -r nixos-blur $install_path
  '';

  meta = with stdenv.lib; { platfotms = platforms.linux; };
}
