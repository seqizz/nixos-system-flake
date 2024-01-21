{ lib
, buildPythonPackage
, pythonOlder
, fetchFromGitHub
, jinja2
, ipython
, networkx
, jsonpickle
}:

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

  # preConfigure = ''
    # patchShebangs autogen.sh
    # ./autogen.sh
  # '';

  # patches = [ ./build_poetry.patch ];

  # checkInputs = [ pytestCheckHook ];

  # Despite living in 'tool.poetry.dependencies',
  # these are only used at build time to process the image resource files
  nativeBuildInputs = [ jinja2 ipython networkx jsonpickle ];

  propagatedBuildInputs = nativeBuildInputs;

  meta = with lib; {
    description = "Diagram as Code";
    homepage    = "https://diagrams.mingrammer.com/";
    license     = licenses.mit;
    maintainers =  with maintainers; [ addict3d ];
  };
}

