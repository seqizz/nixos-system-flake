{
  prev,
  inputs,
  ...
}:
prev.awesome.overrideAttrs (old: {
  pname = "myAwesome";
  version = "master";
  patches = [];
  postPatch = ''
    chmod +x /build/source/tests/examples/_postprocess.lua
    patchShebangs /build/source/tests/examples/_postprocess.lua
  '';
  src = inputs.awesomewm-src;
  lua = prev.lua5_3;
})
