{final, ...}:
final.python3Packages.callPackage ({lib, buildPythonPackage, pythonOlder, fetchFromGitHub, jinja2, ipython, networkx, jsonpickle}:
  buildPythonPackage rec {
    pname = "pyvis";
    version = "unstable-2022-04-15";
    format = "pyproject";
    disabled = pythonOlder "3.6";

    src = fetchFromGitHub {
      owner = "WestHealth";
      repo = "pyvis";
      rev = "eaa24b882401e2e74353efa78bf4e71a880cfc47";
      sha256 = "0zk23mvmma7acfg7rfml5k0ai17w4id58m9a2hfwlm4jfqxqwfd7";
    };

    nativeBuildInputs = [jinja2 ipython networkx jsonpickle];
    propagatedBuildInputs = nativeBuildInputs;

    meta = with lib; {
      description = "Diagram as Code";
      homepage = "https://diagrams.mingrammer.com/";
      license = licenses.mit;
    };
  }) {}
