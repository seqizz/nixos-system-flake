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

    # Rest is sorted
    bandwhich
    bat
    bc
    binutils
    cmake
    compsize # btrfs compression calculator
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
    du-dust # better du alternative
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
    ix # pastebin
    jq
    linuxPackages.perf
    lsof
    man-pages
    mcrypt # for nc file encryption
    moreutils
    mtr
    ncdu # fancy du
    nethogs
    nix-diff
    nix-du
    nix-zsh-completions
    nmap
    ntfs3g
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
    xkcdpass
    youtube-dl
    zip
    zsh-completions
  ];
}
