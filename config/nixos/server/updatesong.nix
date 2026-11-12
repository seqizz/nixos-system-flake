{
  config,
  pkgs,
  ...
}:
let
  hardening = import ../helper-modules/service-hardening.nix;
  # Hardcoded in ../scripts/lastsong.go as well, keep both in sync
  outputFile = "/shared/vhosts/gurkan.in/public/current-song.json";
  blog-song-updater = pkgs.buildGoModule {
    pname = "blog-song-updater";
    version = "0.1.0";
    vendorHash = null;
    dontUnpack = true;
    src = pkgs.runCommand "blog-song-updater-src" { } ''
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
      go build -o bin/blog-song-updater $src/main.go
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
    ldflags = [ ];
  };
in
{
  users.users.song-updater = {
    isSystemUser = true;
    group = "song-updater";
  };
  users.groups.song-updater = { };

  systemd.services.blog-song-updater = {
    description = "Blog Current Song Updater";
    after = [
      "network.target"
      "nginx.service"
    ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = hardening // {
      ExecStart = "${blog-song-updater}/bin/blog-song-updater";
      Restart = "always";
      RestartSec = "10";
      # Dedicated user instead of nginx: a compromise must not be able to
      # rewrite the vhosts. Only the single output file is writable, it has
      # to exist beforehand since ReadWritePaths bind-mounts it.
      User = "song-updater";
      Group = "song-updater";
      ReadWritePaths = [ outputFile ];
      MemoryDenyWriteExecute = true;
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };
}
