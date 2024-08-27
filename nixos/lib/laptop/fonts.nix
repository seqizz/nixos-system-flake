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
      (nerdfonts.override {
        fonts = [
          "Agave"
          "FiraCode"
          "Inconsolata"
          "JetBrainsMono"
          "LiberationMono"
          "DejaVuSansMono"
          "Overpass"
          "SourceCodePro"
          "Ubuntu"
          "UbuntuMono"
        ];
      })
      noto-fonts
      powerline-fonts
      twemoji-color-font
      victor-mono
    ];
  };
}
