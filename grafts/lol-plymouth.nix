{final, inputs, ...}:
final.stdenv.mkDerivation {
  name = "lol";
  version = "unstable-2022-07-08";

  src = inputs.lol-plymouth-src;

  buildInputs = [final.stdenv];

  configurePhase = ''
    install_path=$out/share/plymouth/themes
    mkdir -p $install_path
  '';

  installPhase = ''
    cp -r lol $install_path
  '';

  meta = with final.stdenv.lib; {platfotms = platforms.linux;};
}
