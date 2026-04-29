{
  lib,
  gcc15Stdenv,
  fetchFromGitHub,
  autoreconfHook,
  pkg-config,
  pandoc,
  util-linux,
  acl,
}:

gcc15Stdenv.mkDerivation (finalAttrs: {
  pname = "jai";
  version = "0.4";

  src = fetchFromGitHub {
    owner = "seqizz";
    repo = "jai";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Z38ie3DgnSPqovbQ3jdmKdW40rcJ2PJGfpHYoet2v0k=";
  };

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    pandoc
  ];

  buildInputs = [
    util-linux # libmount
    acl
  ];

  configureFlags = [ "--with-untrusted-user=jai" ];

  meta = {
    description = "Lightweight jail for AI CLIs";
    mainProgram = "jai";
    homepage = "https://jai.scs.stanford.edu";
    changelog = "https://github.com/stanford-scs/jai/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
})
