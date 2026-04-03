{final, ...}:
final.callPackage ({stdenv, fetchFromGitHub, writeTextFile}: let
  config_file = writeTextFile {
    name = "owl.plymouth";
    text = ''
      [Plymouth Theme]
      Name=owl
      Description=display the owl
      Comment=not much
      ModuleName=script

      [script]
      ImageDir=etc/plymouth/themes/owl
      ScriptFile=etc/plymouth/themes/owl/owl.script
    '';
  };
in stdenv.mkDerivation {
  name = "ibm";

  src = fetchFromGitHub {
    owner = "adi1090x";
    repo = "plymouth-themes";
    rev = "bf2f570bee8e84c5c20caac353cbe1d811a4745f";
    sha256 = "0scgba00f6by08hb14wrz26qcbcysym69mdlv913mhm3rc1szlal";
  };

  configurePhase = "mkdir -p $out/share/plymouth/themes/";
  buildPhase = ''substitute ${config_file} "pack_3/owl/owl.plymouth"'';
  installPhase = "cd pack_3 && cp -r owl $out/share/plymouth/themes/";
}) {}
