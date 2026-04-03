# Helper functions for the flake, injected into all graft files as `helpers`
{inputs, pkgs}: {
  # Override a package's src from a flake input
  overrideSrc = pkg: src: pkg.overrideAttrs (_: {inherit src;});

  # Build a vim plugin from a flake input source
  mkVimPlugin = pname: src:
    pkgs.vimUtils.buildVimPlugin {
      inherit pname src;
      version = "master";
    };

  # Import a package from another flake's packages output
  fromFlake = input: input.packages.${pkgs.stdenv.hostPlatform.system}.default;
}
