{prev, ...}:
  prev.lix.overrideAttrs (_: {
    doCheck = false;
    doInstallCheck = false;
  })
