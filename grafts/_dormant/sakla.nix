{final, ...}:
final.python3Packages.callPackage ({lib, fetchgit, pkgs, buildPythonApplication, todoist}:
  buildPythonApplication rec {
    pname = "sakla";
    version = "unstable-2022-08-15";

    src = fetchgit {
      url = "https://git.gurkan.in/gurkan/sakla.git";
      rev = "2e1781b93af2b57b7ece742fc17a5110162a40d4";
      sha256 = "1ggdpgvj6frzr5yam4lj2652ldbgpfai4xynnfg78fyqprgay5qc";
    };

    propagatedBuildInputs = [todoist];

    postInstall = "${pkgs.findutils}/bin/find .";
    doInstallCheck = false;
    doCheck = false;

    meta = with lib; {
      description = "A simple CLI interface for todoist";
      homepage = "https://git.gurkan.in/gurkan/sakla.git";
      license = licenses.agpl3;
      maintainers = ["seqizz"];
      platforms = platforms.linux;
    };
  }) {}
