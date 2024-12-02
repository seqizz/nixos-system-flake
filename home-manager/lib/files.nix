{pkgs, inputs, config, ...}: let
  sync = "/home/gurkan/syncfolder";
  secrets = import ./secrets.nix {pkgs = pkgs;};
  fileAssociations = import ./file-associations.nix;
in {
  xdg = {
    portal = {
      enable = true;
      config.common.default = "gtk";
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
      ];
    };
    mimeApps = {
      enable = true;
      defaultApplications = fileAssociations;
    };
    configFile = {
      "tridactyl/tridactylrc".source = ./config_files/tridactyl/tridactylrc;
      "tridactyl/themes/mytheme.css".source = ./config_files/tridactyl/mytheme.css;

      "ruff/ruff.toml".source = ./config_files/ruff.toml;

      "mimeapps.list".force = true;

      "puppet_4chars.rb".text = ''
        # Used for puppet-lint, makes default indentation 4 spaces
        PuppetLint.configuration.chars_per_indent = 4
      '';

      "Yubico/u2f_keys".text = secrets.yubicoU2FKeys;
      "Yubico/YKPersonalization.conf".source = ./config_files/YKPersonalization.conf;

      "greenclip.toml".source = ./config_files/greenclip.toml;

      "tig/config".source = ./config_files/tig;

      "flameshot/flameshot.ini".source = ./config_files/flameshot.ini;

      "loose/config.yaml".source = ./config_files/loose;

      "picom.conf".source = ./config_files/picom.conf;

      "libinput-gestures.conf".source = ./config_files/libinput-gestures.conf;

      "pylintrc".source = ./config_files/pylintrc;

      "extrakto/extrakto.conf".source = ./config_files/extrakto.conf;

      "geany/filedefs/filetypes.common".source = ./config_files/geany_styling;

      "delta-theme.gitconfig".source = ./config_files/delta-theme;

      "yamlfix_config.toml".source = ./config_files/yamlfix_config.toml;

      "direnv/direnvrc".source = ./config_files/direnvrc;

      "ghorg/conf.yaml".source = ./config_files/ghorg;
      "ghorg/reclone.yaml".text = secrets.ghorgReclone;
    };

    # Placeholder for vim's undodir
    dataFile = {
      "vim-undo/.keep".text = "";
    };
  };

  home.file = {
    ".zshnix".source = pkgs.substituteAll {
      src = ./config_files/zsh_nix;
      openscPath = "${pkgs.opensc.outPath}";
    };

    ".config/awesome/lain".source = inputs.lain-src;

    ".gist".text = secrets.gistSecret;

    # TODO: This shit is world-readable
    ".tarsnap.key".text = secrets.tarsnapKey;

    "devel".source = config.lib.file.mkOutOfStoreSymlink "/devel";

    ".rustypaste/config.toml".text = secrets.rustypasteSecret;

    ".tarsnaprc".source = ./config_files/tarsnaprc;

    ".thunderbird/profiles.ini".source = ./config_files/thunderbird/profiles.ini;
    ".thunderbird/gurkan.default/user.js".source = ./config_files/thunderbird/user.js;
    ".thunderbird/gurkan.default/chrome/userChrome.css".source = ./config_files/thunderbird/userChrome.css;

    ".mozilla/firefox/installs.ini".source = ./config_files/firefox/installs.ini;
    ".mozilla/firefox/profiles.ini".source = ./config_files/firefox/profiles.ini;
    ".mozilla/firefox/gurkan.default/user.js".source = ./config_files/firefox/user.js;
    ".mozilla/firefox/gurkan.default/chrome/userChrome.css".source = ./config_files/firefox/userChrome.css;
    ".mozilla/native-messaging-hosts/tridactyl.json".source = "${pkgs.tridactyl-native}/lib/mozilla/native-messaging-hosts/tridactyl.json";

    ".trc".text = secrets.rubyTwitterSecret;

    ".proxychains/proxychains.conf".source = ./config_files/proxychains.conf;
  };
}
