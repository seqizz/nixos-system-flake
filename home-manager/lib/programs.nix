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
      enable = true;
      userEmail = secrets.gitUserEmail;
      userName = secrets.gitUserName;
      delta = {
        enable = true;
        options = {
          dark = "true";
          true-color = "always";
          features = "mytheme";
        };
      };
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

    browserpass = {
      enable = true;
      browsers = ["firefox"];
    };

    # Bug: https://github.com/nix-community/home-manager/issues/1586
    # firefox = {
    #   enable = true;
    #   package = pkgs.wrapFirefox pkgs.firefox-unwrapped.override {
    #     nativeMessagingHosts = with pkgs; [
    #       browserpass
    #       nur.repos.wolfangaukang.vdhcoapp
    #       tridactyl-native
    #     ];
    #   };
    #   profiles.declaredProfile = {
    #     name = "gurkan-home-manager";
    #     extraConfig = builtins.readFile ./config_files/firefox/user.js;
    #     userChrome = builtins.readFile ./config_files/firefox/userChrome.css;
    #   };
    # };

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
        kb-cancel = "Control+c,Escape,Control+g,Control+bracketleft";
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

