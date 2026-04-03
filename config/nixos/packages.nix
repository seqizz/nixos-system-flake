{
  pkgs,
  config,
  lib,
  ...
}: {
  programs = {
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc.lib
        zlib
      ];
    };
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
    git = {
      enable = true;
      lfs.enable = true;
      package = pkgs.unstable.git;
    };
    yazi = {
      enable = true;
      package = pkgs.unstable.yazi;
      plugins = {
        "xclip-system-clipboard.yazi" = pkgs.yazi-xclip-systemclipboard;
      };
      settings = {
        yazi.mgr = {
          ratio = [1 4 3];
          sort_by = "mtime";
          sort_sensitive = false;
          sort_reverse = false;
          sort_dir_first = true;
          show_hidden = false;
          show_symlink = true;
          scrolloff = 5;
          mouse_events = ["click" "scroll"];
        };
        theme.mgr = {
          tab_width = 20;
        };
        keymap.mgr.prepend_keymap = [
          {
            on = ["<C-y>"];
            run = "plugin xclip-system-clipboard";
          }
        ];
      };
    };
    firejail.enable = true;
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
    igrep

    # Code formatters
    alejandra # Nix
    nodePackages.fixjson
    pkgs.unstable.ruff
    rubyPackages_3_3.rubocop
    shellcheck
    stylua
    taplo # toml
    typstyle
    jsbeautifier

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
      zlibSupport = true;
      zstdSupport = true;
    })
    direnv # .envrc runner
    dmidecode
    dnsutils
    docker-compose
    dool
    e2fsprogs
    ffmpeg
    file
    fx # JSON viewer
    fzf
    gcc
    glibcLocales
    gnumake
    go
    htop
    iftop
    inetutils # telnet
    iotop
    jq
    perf
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
    uv
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
