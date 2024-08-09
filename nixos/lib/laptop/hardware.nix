{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./helper-modules/usb-wakeup-disable.nix
    ./helper-modules/v4l2loopback.nix
  ];

  hardware = {
    bluetooth.enable = true;
    v4l2loopback.enable = false; # FIXME: Broken on latest for now
    logitech.wireless.enable = true;
    keyboard.qmk.enable = true;
    enableRedistributableFirmware = true;

    firmware = [pkgs.firmwareLinuxNonfree];

    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        vaapiIntel
        vaapiVdpau
        libvdpau-va-gl
        intel-media-driver
        vulkan-loader
        libva
      ];
    };

    usb.wakeupDisabled = [
      {
        # Logitech G413 gaming keyboard
        vendor = "046d";
        product = "c33a";
      }
      {
        # Damn fingerprint device
        vendor = "27c6";
        product = "633c";
      }
      {
        # Extra sensitive touchpad
        vendor = "2c2f";
        product = "002b";
      }
      {
        # Logitech unifying receiver (mouse)
        vendor = "046d";
        product = "c52b";
      }
      {
        # Logitech unifying receiver (kb/mouse combo)
        vendor = "046d";
        product = "c534";
      }
      {
        # ZSA Moonlander
        vendor = "3297";
        product = "1969";
      }
      {
        # Keychron V3
        vendor = "3434";
        product = "0333";
      }
    ];
  };
}
