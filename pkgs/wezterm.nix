{ stdenv
, rustPlatform
, makeRustPlatform
, lib
, fetchFromGitHub
, pkg-config
, fontconfig
, python3
, openssl
, openssh
, perl
, dbus
, libX11
, xcbutil
, libxcb
, ncurses
, xcbutilkeysyms
, xcbutilimage
, xcbutilrenderutil
, xcbutilwm # contains xcb-ewmh among others
, libxkbcommon
, libglvnd # libEGL.so.1
, egl-wayland
, wayland
, libGLU
, libGL
, freetype
, zlib
, rust-bin  # Comes from https://github.com/oxalica/rust-overlay
}:
let
  runtimeDeps = [
    libX11
    xcbutil
    libxcb
    xcbutilkeysyms
    xcbutilwm
    xcbutilimage
    xcbutilrenderutil
    libxkbcommon
    dbus
    libglvnd
    zlib
    egl-wayland
    wayland
    libGLU
    libGL
    fontconfig
    freetype
    openssl
  ];
in
rustPlatform.buildRustPackage {
  name = "wezterm";
  src = fetchFromGitHub {
    owner = "wez";
    repo = "wezterm";
    rev = "a7c6ea8c1ed93396bd2c3d6cd0e99119a2c8bdd9";
    fetchSubmodules = true;
    sha256 = "0l9ysylxkaqglgvzjc7z8lbnwb11xhzgai4wrwgcc8is03h47l8s";
  };

  cargoLock = {
    lockFile = ./WeztermCargo.lock;
    outputHashes = {
      "image-0.24.5" = "sha256-fTajVwm88OInqCPZerWcSAm1ga46ansQ3EzAmbT58Js=";
      "xcb-imdkit-0.2.0" = "sha256-L+NKD0rsCk9bFABQF4FZi9YoqBHr4VAZeKAWgsaAegw=";
      "xcb-1.2.1" = "sha256-zkuW5ATix3WXBAj2hzum1MJ5JTX3+uVQ01R1vL6F1rY=";
    };
  };

  cargoHash = "";

  nativeBuildInputs = [
    pkg-config
    python3
    perl
    ncurses
    rust-bin.nightly.latest.default
  ];

  doCheck = false;

  outputs = [ "out" "terminfo" ];

  buildInputs = runtimeDeps;

  postPatch = ''
    echo "latest main on `date`" > .tag
  '';

  preFixup = lib.optionalString stdenv.isLinux ''
    for artifact in wezterm wezterm-gui wezterm-mux-server strip-ansi-escapes; do
      patchelf --set-rpath "${lib.makeLibraryPath runtimeDeps}" $out/bin/$artifact
    done
  '' + lib.optionalString stdenv.isDarwin ''
    mkdir -p "$out/Applications"
    OUT_APP="$out/Applications/WezTerm.app"
    cp -r assets/macos/WezTerm.app "$OUT_APP"
    rm $OUT_APP/*.dylib
    cp -r assets/shell-integration/* "$OUT_APP"
    ln -s $out/bin/{wezterm,wezterm-mux-server,wezterm-gui,strip-ansi-escapes} "$OUT_APP"
  '';

  postInstall = ''
    mkdir -p $terminfo/share/terminfo/w $out/nix-support
    tic -x -o $terminfo/share/terminfo termwiz/data/wezterm.terminfo
    echo "$terminfo" >> $out/nix-support/propagated-user-env-packages
  '';

  # prevent further changes to the RPATH
  dontPatchELF = true;

  meta = with lib; {
    description = "A GPU-accelerated cross-platform terminal emulator and multiplexer written by @wez and implemented in Rust";
    homepage = "https://wezfurlong.org/wezterm";
    license = licenses.mit;
    maintainers = with maintainers; [ seqizz ];
    platforms = platforms.unix;
  };
}
