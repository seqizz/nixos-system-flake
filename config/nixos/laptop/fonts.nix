{ pkgs, config, ... }:
{
  fonts = {
    fontconfig= {
      enable = true;
      defaultFonts = {
        emoji = [ "Noto Color Emoji" ];
      };
      antialias = true;
      cache32Bit = true;
      hinting.enable = true;
      hinting.autohint = true;
    };
    fontDir.enable = true;
    packages = with pkgs; [
      comic-relief
      corefonts
      font-awesome_4
      font-awesome
      ionicons
      liberation_ttf
      lineicons
      nerd-fonts.agave
      nerd-fonts.fira-code
      nerd-fonts.inconsolata
      nerd-fonts.jetbrains-mono
      nerd-fonts.liberation
      nerd-fonts.dejavu-sans-mono
      nerd-fonts.overpass
      nerd-fonts.sauce-code-pro
      nerd-fonts.ubuntu
      nerd-fonts.ubuntu-mono
      noto-fonts
      powerline-fonts
      twemoji-color-font
      victor-mono
    ];
  };
}
