{
  lib,
  pkgs,
  installShellFiles,
  inputs,
  jc,
  filelock,
  pyyaml,
  typing-extensions,
  xdg-base-dirs,
  yamale,
  shtab,
  callPackage,
  buildPythonApplication,
  poetry-core,
}: let
  pyedid = callPackage ./pyedid.nix {};
in
  buildPythonApplication rec {
    pname = "loose";
    version = "master";
    pyproject = true;

    src = inputs.loose-src;

    nativeBuildInputs = [
      poetry-core
      installShellFiles
    ];

    buildInputs = [
      shtab # For command line completion
    ];

    propagatedBuildInputs = [
      filelock
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
      homepage = "https://git.gurkan.in/gurkan/loose";
      license = licenses.gpl3;
      maintainers = ["seqizz"];
      platforms = platforms.linux;
    };
  }
