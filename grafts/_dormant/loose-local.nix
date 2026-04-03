# Old local loose package definition. Superseded by grafts/loose.nix (flake import).
# Requires: inputs.loose-src in flake.nix (already present) + pyedid graft
{final, inputs, ...}:
final.python3Packages.callPackage ({
  lib,
  pkgs,
  installShellFiles,
  buildPythonApplication,
  poetry-core,
  jc,
  filelock,
  pyyaml,
  typing-extensions,
  xdg-base-dirs,
  yamale,
  shtab,
  ...
}:
  buildPythonApplication rec {
    pname = "loose";
    version = "master";
    pyproject = true;

    src = inputs.loose-src;

    nativeBuildInputs = [poetry-core installShellFiles];
    buildInputs = [shtab];

    propagatedBuildInputs = [
      filelock
      jc
      pkgs.xorg.xrandr
      final.pyedid  # from grafts/_dormant/pyedid.nix
      pyyaml
      typing-extensions
      xdg-base-dirs
      yamale
    ];

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
  }) {}
