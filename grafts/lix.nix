{prev, ...}: let
  # Pin curl to 8.20.0 — newer curl breaks lix's HTTP store fetcher.
  # See: https://github.com/NixOS/nix/issues/... (community workaround)
  pinnedCurl = prev.curl.overrideAttrs (_: {
    version = "8.20.0";
    src = prev.fetchurl {
      urls = [
        "https://curl.haxx.se/download/curl-8.20.0.tar.xz"
        "https://github.com/curl/curl/releases/download/curl-8_20_0/curl-8.20.0.tar.xz"
      ];
      hash = "sha256-Y/4twUi6DOromSLvg49+XJRicsLni3xZ+rS3nTziuJY=";
    };
    patches = [];
  });
in
  (prev.lix.override {curl = pinnedCurl;}).overrideAttrs (_: {
    doCheck = false;
    doInstallCheck = false;
  })
