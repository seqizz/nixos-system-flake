{
  pkgs,
  config,
  lib,
  ...
}:
{
  programs = {
    zsh = {
      enable = true;
      enableGlobalCompInit = false;
    };
    tmux = {
      enable = true;
      terminal = "screen-256color";
    };
    less.enable = true;
    nix-index-database.comma.enable = true;
  };

  environment.systemPackages = with pkgs; [
    (python3.withPackages (ps:
      with ps; [
        black
        ipython
        isort
        pep8
        pip
        poetry-core
        setuptools
        virtualenv
      ]))

    # unstable is better for some packages
    pkgs.unstable.rustypaste-cli
    pkgs.unstable.sheldon # zsh plugin manager
    pkgs.unstable.igrep

    # Code formatters
    alejandra # Nix
    nodePackages.fixjson
    puppet-lint
    shellcheck
    stylua
    taplo # toml
    pkgs.unstable.ruff
    pkgs.unstable.ruff-lsp

    # Rest is sorted
    bandwhich
    bat
    bc
    binutils
    bpftrace
    cmake
    compsize # btrfs compression calculator
    conntrack-tools
    cpulimit
    cryptsetup
    (curl.override {
      http3Support = true;
      idnSupport = true;
      brotliSupport = true;
      openssl = pkgs.quictls;
      zstdSupport = true;
    })
    direnv # .envrc runner
    dmidecode
    dnsutils
    docker-compose
    dstat
    ffmpeg
    file
    fzf
    gcc
    git
    glibcLocales
    gnumake
    go
    htop
    iftop
    inetutils # telnet
    iotop
    jq
    linuxPackages.perf
    lsof
    man-pages
    mcrypt # for nc file encryption
    moreutils
    mtr
    ncdu # fancy du
    nethogs
    nix-du
    nix-zsh-completions
    nmap
    ntfs3g
    nvd
    openssl
    p7zip
    pciutils
    pkg-config
    psmisc
    ripgrep # find faster
    sqlite
    sshfs-fuse
    stow # Supercharged symlinks
    sysstat
    tailspin
    tcpdump
    thttpd # for htpasswd
    tig # git helper
    time
    toilet # useless cool stuff
    universal-ctags
    unzip
    usbutils
    vgrep
    vimwiki-markdown
    wget
    wireguard-tools
    xkcdpass
    yt-dlp
    zip
    zsh-completions
  ];
}
