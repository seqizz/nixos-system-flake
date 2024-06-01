{ lib
, pkgs
, installShellFiles
, python3Packages
, inputs
}:
let
  pyedid = python3Packages.callPackage ./pyedid.nix {};
in
python3Packages.buildPythonApplication rec {

  pname = "loose";
  version = "unstable-2024-01-18";
  pyproject = true;

  src = inputs.loose-src;

  nativeBuildInputs = with python3Packages; [
    poetry-core
    installShellFiles
  ];

  buildInputs = with python3Packages; [
    shtab # For command line completion
  ];

  propagatedBuildInputs = with python3Packages; [
    jc
    pkgs.xorg.xrandr
    pyedid
    pyyaml
    typing-extensions
    xdg-base-dirs
    yamale
  ];

  # Sadly shtab doesn't have fish completion yet
  postInstall = ''
    installShellCompletion --cmd loose \
      --bash <($out/bin/loose -s bash) \
      --zsh <($out/bin/loose -s zsh)
  '';

  meta = with lib; {
    description = "Another xrandr wrapper for multi-monitor setups";
    homepage = https://git.gurkan.in/gurkan/loose;
    license = licenses.gpl3;
    maintainers = [ "seqizz" ] ;
    platforms = platforms.linux;
  };
}
