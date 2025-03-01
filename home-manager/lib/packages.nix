{
  config,
  pkgs,
  inputs,
  ...
}: let
  my_scripts = import ./scripts.nix {pkgs = pkgs;};
in {
  nixpkgs = {
    config = {
      enable = true;
      allowUnfree = true;
      # Quick-overrides
      packageOverrides = pkgs: {
        nur-lunwill42 = import (
          pkgs.fetchFromGitHub {
            owner = "lunkwill42";
            repo = "nur-packages";
            rev = "master";
            sha256 = "sha256-IewS/HSyPvyBiE2oWgQeVgvwcgbai1qfjiacYizg3RA=";
          }
        ) {inherit pkgs;};
      };
      # packageOverrides = pkgs: rec {
      # browserpass = oldversion.browserpass;  # Reference override: https://github.com/NixOS/nixpkgs/issues/236074
      # @Reference patching apps
      # krunner-pass = pkgs.krunner-pass.overrideAttrs (attrs: {
      # patches = attrs.patches ++ [ ~/syncfolder/dotfiles/nixos/home/gurkan/.config/nixpkgs/modules/packages/pass-dbus.patch ];
      # });
      # weechat = (pkgs.weechat.override {
      # configure = { availablePlugins, ... }: {
      # plugins = with availablePlugins; [
      # (python.withPackages (ps: with ps; [
      # websocket_client
      # dbus-python
      # notify
      # ]))
      # ];
      # };
      # });
      # };
      # @Reference sometimes needed
      # allowBroken = true;
    };
  };

  home.packages = with pkgs; [
    (gimp-with-plugins.override {plugins = with gimpPlugins; [gmic];})
    (pass.withExtensions (ps: with ps; [pass-genphrase]))
    (python3.withPackages (ps:
      with ps; [
        adminapi
        coverage
        flake8
        ipython
        libtmux
        libvirt
        netaddr
        pep8
        pip
        pylint
        pynvim
        pysnooper
        pyupgrade
        pyyaml
        requests
        setuptools
        tapop100
        vimwiki-markdown
        virtualenv
        vulture # find unused code
        xlib
      ]))

    # non-stable stuff, subject to change
    pkgs.unstable.tdesktop # telegram
    firefox # was unstable, broke webgl
    pkgs.unstable.wezterm
    pkgs.unstable.discord
    thunderbird

    # NUR packages @Reference, mostly does not work / maintained
    # config.nur.repos.wolfangaukang.vdhcoapp
    # config.nur.repos.mic92.reveal-md
    nur-lunwill42.puppet-lint

    # Rest is sorted
    # Commented ones are either not needed or reminder for single-use
    adbfs-rootless
    alacritty
    alttab
    appimage-run
    arandr # I might need manual xrandr one day
    arc-kde-theme # for theming kde apps
    arc-theme
    ark
    blueman
    brightnessctl
    calibre
    chromium
    dconf # some gnome apps keep its config in this shit e.g. shotwell
    ffmpeg
    ffmpegthumbs
    flameshot
    geany
    ghorg # Clone whole organizations from git remotes
    git-filter-repo # Amazing tool to rewrite history 😈
    gitstatus
    glxinfo
    graphviz # some rarely-needed weird tools
    home-manager # wow, flakes are amazing 😒
    imagemagick
    inotify-tools
    jmtpfs # mount MTP devices easily
    # kde-cli-tools # required to open kde-gtk-config
    # kde-gtk-config # best GTK theme selector
    libnotify
    libreoffice
    hunspell # For spellcheck on Libreoffice
    hunspellDicts.de_DE
    hunspellDicts.en_US
    aspell # If any app uses aspell
    aspellDicts.de
    aspellDicts.en
    aspellDicts.tr
    loose # Fuck yeah
    nomacs
    meld # GUI diff tool
    my_scripts.bulb-toggle
    my_scripts.firefox-tempprofile
    my_scripts.git-browse-origin
    my_scripts.git-cleanmerged
    my_scripts.psitool-script
    my_scripts.rofi-subsuper
    my_scripts.tarsnap-dotfiles
    my_scripts.update-song
    my_scripts.xinput-toggle
    nfpm
    onboard # on-screen keyboard
    opera # Good to have as alternative
    pamixer # pulseaudio mixer
    papirus-icon-theme
    pasystray
    pavucontrol
    pcmanfm-qt # A file-manager which fucking works
    pcsx2 # PS2 emulator
    picom # X compositor which sucks, also do not use services.picom
    pkgs.unstable.pinentry-rofi
    playerctl
    poetry
    proxychains
    qpwgraph # Graphical pipewire plumbing
    reveal-md
    rofi-pulse-select
    qpdfview
    # qt5ct # QT5 theme selector
    # sieve-editor-gui # Mail filter editor
    simplescreenrecorder
    slock
    spotify
    steam-run # helper tool for running shitty binaries
    tarsnap
    update-nix-fetchgit
    vial # QMK keyboard configurator
    wally-cli
    xautomation
    xclip
    xcolor # color picker
    xdotool
    xorg.xdpyinfo
    xorg.xev
    xorg.xkill
    xorg.xmodmap
    xorg.xwininfo
    xournal # annotate pdfs
    xsel
    yamlfix
  ];
}
#  vim: set ts=2 sw=2 tw=0 et :

