{ config, pkgs, inputs, ...}:

let
  my_scripts = (import ./scripts.nix {pkgs = pkgs;});
in

{
  nixpkgs = {
    config = {
      enable = true;
      allowUnfree = true;
      # Quick-overrides
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
    ( gimp-with-plugins.override { plugins = with gimpPlugins; [ gmic ]; })
    ( pass.withExtensions ( ps: with ps; [ pass-genphrase ]))
    ( python3.withPackages ( ps: with ps; [
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
    steam
    pkgs.unstable.tdesktop # telegram
    pkgs.unstable.firefox # fucker crashing on me with 114.0.2
    # pkgs.unstable.wezterm
    inputs.wezterm.packages.x86_64-linux.default

    # NUR packages
    config.nur.repos.wolfangaukang.vdhcoapp
    config.nur.repos.mic92.reveal-md

    # Rest is sorted
    adbfs-rootless
    alacritty
    alttab
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
    loose # Fuck yeah
    lxqt.lximage-qt
    meld # GUI diff tool
    mpv
    my_scripts.bulb-toggle
    my_scripts.git-browse-origin
    my_scripts.git-cleanmerged
    my_scripts.psitool-script
    my_scripts.rofi-subsuper
    my_scripts.tarsnap-dotfiles
    my_scripts.workman-toggle
    my_scripts.xinput-toggle
    nfpm
    onboard # on-screen keyboard
    opera # Good to have as alternative
    pamixer # pulseaudio mixer
    papirus-icon-theme
    # paoutput
    pasystray
    pavucontrol
    pcmanfm-qt # A file-manager which fucking works
    # pdftk # split-combine pdfs
    picom # X compositor which sucks, also do not use services.picom
    pkgs.unstable.pinentry-rofi
    playerctl
    poetry
    # poppler_utils # for pdfunite
    proxychains
    rofi-pulse-select
    qpdfview
    # qt5ct # QT5 theme selector
    simplescreenrecorder
    slock
    spotify
    steam-run # helper tool for running shitty binaries
    tarsnap
    taskwarrior
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
