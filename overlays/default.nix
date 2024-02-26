# This file defines overlays
{inputs, ...}: let
  getSrcFromInput = pkg: src: pkg.overrideAttrs (_: {inherit src;});
in {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev:
    import ../pkgs {
      pkgs = final;
      inputs = inputs;
    };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: rec {
    vimwiki-markdown = getSrcFromInput prev.vimwiki-markdown inputs.vimwiki-markdown-src;
    mpv = prev.mpv-unwrapped.override {
      ffmpeg = prev.ffmpeg_5-full;
    };
    greenclip = getSrcFromInput prev.greenclip inputs.greenclip-src;
    sd-switch = inputs.sd-switch-src.packages.${final.system}.default;
    loose = final.callPackage ../pkgs/loose.nix {inherit inputs;};
    lol-plymouth = final.callPackage ../pkgs/lol-plymouth.nix {inherit inputs;};
    # @Reference: Overriding rust stuff via cargoDeps
    # Seems like original author has passed away, RIP @jD91mZM2
    xidlehook = prev.xidlehook.overrideAttrs (out: rec {
      version = "unstable-2022-05-18";
      src = inputs.xidlehook-src;
      cargoDeps = out.cargoDeps.overrideAttrs (_: {
        inherit src; # We need to pass "src" here again
        # TODO: Find a way to define this on inputs?
        outputHash = "sha256-Iuri3dOLzrfTzHvwOKcZrVJFotqrGlM6EeuV29yqz+U=";
      });
    });
    picom = prev.picom.overrideAttrs (old: {
      version = "master";
      src = inputs.picom-src;
      buildInputs = with final;
        [
          unstable.cmake
          unstable.libev
          unstable.xorg.xcbutil
          unstable.pcre2
          unstable.epoxy
        ]
        ++ old.buildInputs;
    });

    awesome = prev.awesome.overrideAttrs (old: rec {
      pname = "myAwesome";
      version = "master";
      patches = [];
      postPatch = ''
        chmod +x /build/source/tests/examples/_postprocess.lua
        patchShebangs /build/source/tests/examples/_postprocess.lua
      '';
      src = inputs.awesomewm-src;
      lua = prev.lua5_3;
    });

    # Neovim plugins
    plugin = pname: src:
      prev.vimUtils.buildVimPlugin {
        inherit pname src;
        version = "master";
      };
    vim-puppet-4tabs = plugin "vim-puppet-4tabs" inputs.vim-puppet-4tabs-src;
    vim-yadi = plugin "vim-yadi" inputs.vim-yadi-src;
    yanky = plugin "yanky" inputs.yanky-src;
    leap = plugin "leap" inputs.leap-src;
    trailblazer = plugin "trailblazer" inputs.trailblazer-src;
    commentnvim = plugin "commentnvim" inputs.commentnvim-src;
    telescope-file-browser = plugin "telescope-file-browser" inputs.telescope-file-browser-src;
    vim-colorschemes-forked = plugin "vim-colorschemes-forked" inputs.vim-colorschemes-forked-src;
    copilot = plugin "copilot" inputs.copilot-src;
    undowarn = plugin "undowarn" inputs.undowarn-src;
    neovim-project = plugin "neovim-project" inputs.neovim-project-src;
    neovim-session-manager = plugin "neovim-session-manager" inputs.neovim-session-manager-src;
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
  # same for oldversion
  oldversion-packages = final: _prev: {
    oldversion = import inputs.nixpkgs-2211 {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}
