{ pkgs, config, ... }:
{
  fonts = {
    fontconfig = {
      enable = true;

      defaultFonts = {
        sansSerif = [
          "Noto Sans"
          "Liberation Sans"
          "DejaVu Sans"
        ];

        serif = [
          "Noto Serif"
          "Liberation Serif"
          "DejaVu Serif"
        ];

        monospace = [
          "JetBrainsMono Nerd Font"
          "FiraCode Nerd Font"
          "DejaVu Sans Mono"
        ];

        emoji = [
          "Noto Color Emoji"
        ];
      };

      antialias = true;
      cache32Bit = true;

      hinting = {
        enable = true;
        autohint = false; # Prefer native font hinting; autohint can make glyphs look uneven
        style = "slight";
      };

      subpixel = {
        rgba = "rgb"; # Change to "bgr" only if your display panel is BGR
      };
    };

    fontDir.enable = true;

    packages = with pkgs; [
      corefonts
      liberation_ttf

      noto-fonts
      noto-fonts-color-emoji

      font-awesome_4
      font-awesome
      ionicons
      lineicons
      powerline-fonts

      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.inconsolata
      nerd-fonts.dejavu-sans-mono
      nerd-fonts.liberation
      nerd-fonts.ubuntu
      nerd-fonts.ubuntu-mono

      comic-relief
      victor-mono
    ];
  };
}
