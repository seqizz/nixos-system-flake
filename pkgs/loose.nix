{
  lib,
  pkgs,
  installShellFiles,
  python3Packages,
  inputs,
}: let
  pyedid = python3Packages.callPackage ./pyedid.nix {};
in
  python3Packages.buildPythonApplication rec {
    pname = "loose";
    version = "master";
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
      export HOME=$TMPDIR
      $out/bin/loose -s bash > $HOME/loose.bash
      $out/bin/loose -s zsh > $HOME/loose.zsh
        installShellCompletion --cmd loose \
          --bash $HOME/loose.bash \
          --zsh $HOME/loose.zsh
    '';

    meta = with lib; {
      description = "Another xrandr wrapper for multi-monitor setups";
      homepage = https://git.gurkan.in/gurkan/loose;
      license = licenses.gpl3;
      maintainers = ["seqizz"];
      platforms = platforms.linux;
    };
  }
