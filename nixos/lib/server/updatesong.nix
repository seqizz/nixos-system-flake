{
  config,
  pkgs,
  ...
}: let
  blog-song-updater = pkgs.buildGoModule {
    pname = "blog-song-updater";
    version = "0.1.0";
    vendorHash = null;
    dontUnpack = true;
    src = pkgs.runCommand "blog-song-updater-src" {} ''
      mkdir -p $out
      cat > $out/go.mod <<EOF
        module blog-song-updater
        go 1.21
      EOF
      cat > $out/main.go <<EOF
        ${builtins.readFile ../scripts/lastsong.go}
      EOF
    '';
    buildPhase = ''
      mkdir bin
      # Add debug flags and disable stripping
      go build -v -x -gcflags="all=-N -l" -o bin/blog-song-updater $src/main.go
    '';
    installPhase = ''
      install -dm755 $out/bin
      mv bin/blog-song-updater $out/bin/blog-song-updater
    '';
    # Ensure proper CGO settings
    env = {
      CGO_ENABLED = "0";
    };
    # Remove version reference
    ldflags = [];
  };
in {
  systemd.services.blog-song-updater = {
    description = "Blog Current Song Updater";
    after = ["network.target" "nginx.service"];
    wantedBy = ["multi-user.target"];

    environment = {
      # Add some debug environment
      GODEBUG = "http2debug=2";
      LOG_LEVEL = "debug";
    };

    serviceConfig = {
      ExecStart = "${blog-song-updater}/bin/blog-song-updater";
      Restart = "always";
      RestartSec = "10";
      User = "nginx";
      ReadWritePaths = ["/shared/vhosts/gurkan.in/public"];
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };
}

