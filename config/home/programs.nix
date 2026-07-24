{
  config,
  pkgs,
  ...
}: let
  secrets = import ./secrets.nix {pkgs = pkgs;};
  gitConfigInnoPath = (pkgs.writeText "git-config-inno" secrets.gitConfigInno).outPath;
in {
  programs = {
    git = {
      # XXX: Duplicated settings, also defined in nixos/lib/packages.nix, fix later
      enable = true;
      lfs.enable = true;
      package = pkgs.unstable.git;
      settings.user = {
        email = secrets.gitUserEmail;
        name = secrets.gitUserName;
      };
      # XXX: Unsafe before 2.53
      # settings.blame = {
      # ignoreRevsFile = ":(optional).git-blame-ignore-revs";
      # };
      includes = [
        {
          condition = "gitdir:devel/ig/**";
          path = gitConfigInnoPath;
        }
        {
          condition = "gitdir:devel/puppet/**";
          path = gitConfigInnoPath;
        }
        {
          path = "/home/gurkan/.config/delta-theme.gitconfig";
        }
      ];
    };

    delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        dark = "true";
        true-color = "always";
        features = "mytheme";
      };
    };

    browserpass = {
      enable = true;
      browsers = ["firefox"];
    };

    # WhatsApp PWA
    zapzap.enable = true;

    # TODO for when I'm not lazy
    # claude-code = {
    #   enable = true;
    #   skills = secrets.claudeSkills;
    # };

    firefox = {
      enable = true;
      # Pin the legacy profile location. Default flips to the XDG path at
      # stateVersion 26.05; keep the existing ~/.mozilla/firefox to avoid
      # moving the profile dir.
      configPath = ".mozilla/firefox";
      # Bridges for browserpass / vdhcoapp / tridactyl. These are native
      # messaging hosts, not the browser extensions themselves.
      nativeMessagingHosts = with pkgs; [
        browserpass
        # nur.repos.wolfangaukang.vdhcoapp # stale git rev upstream, breaks eval
        tridactyl-native
      ];
      profiles.gurkan = {
        # Reuse the existing profile dir so history/logins/extensions survive.
        path = "gurkan.default";
        isDefault = true;
        # Keep the curated user.js verbatim (comments preserved) instead of
        # converting every pref into a settings attr.
        extraConfig = builtins.readFile ./config_files/firefox/user.js;
        userChrome = builtins.readFile ./config_files/firefox/userChrome.css;
        # Extensions left unmanaged on purpose: keep manual install/upgrade/
        # remove via the Firefox UI. TST's own style (treestyletab.css) is not
        # declarable anyway.
      };
    };

    rbw = {
      enable = true;
      settings = {
        base_url = secrets.passwordVaultBaseUrl;
        email = secrets.passwordVaultEmail;
        pinentry = pkgs.unstable.pinentry-rofi;
        lock_timeout = 64800; # 18 hours
      };
    };

    rofi = {
      enable = true;
      package = pkgs.rofi.override {
        plugins = with pkgs; [
          rofi-emoji
          rofi-calc
        ];
      };
      pass = {
        enable = true;
        extraConfig = ''
          USERNAME_field='login'
          help_color='#4872FF'
        '';
      };
      font = "FiraCode Nerd Font 14";
      theme = "glue_pro_blue";
      extraConfig = {
        matching = "regex";
        max-history-size = 500;
        kb-clear-line = "Control+a";
        kb-move-front = "";
        kb-cancel = "Escape,Control+g,Control+bracketleft";
      };
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
    mpv.enable = true;
  };
}
#  vim: set ts=2 sw=2 tw=0 et :

