{prev, ...}:
# https://nixpk.gs/pr-tracker.html?pr=569595
prev.solaar.overridePythonAttrs (_: {
  doCheck = false;
})
