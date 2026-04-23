{
  config,
  lib,
  pkgs,
  ...
}:
# @Reference see below
# let
# signal_script = pkgs.writeScript "signal_script" ''
# #!${pkgs.bash}/bin/bash -eu
# ${pkgs.coreutils}/bin/coreutils --coreutils-prog=sleep 1
# ${pkgs.dbus}/bin/dbus-send --system --type=signal / "$1"
# '';
# in
{
  # @Reference for tunables of pulseaudio
  # sound.enable = true;
  # hardware = {
  # pulseaudio = {
  # enable = true;
  # package = pkgs.pulseaudioFull;
  # support32Bit = true;
  # extraModules = [ pkgs.pulseaudio-modules-bt ];
  # # @Reference to blacklist any devices' auto-switch
  # # load-module module-switch-on-connect blacklist=""
  # extraConfig = ''
  # load-module module-switch-on-connect blacklist="USB|Dock"
  # load-module module-alsa-card device_id="1" name="usb-Logitech_Logitech_G933_Gaming_Wireless_Headset-00" card_name="alsa_card.usb-Logitech_Logitech_G933_Gaming_Wireless_Headset-00" namereg_fail=false tsched=yes fixed_latency_range=yes ignore_dB=no deferred_volume=yes use_ucm=yes avoid_resampling=yes card_properties="module-udev-detect.discovered=1" tsched_buffer_size=65536 tsched_buffer_watermark=20000
  # '';
  # };
  # };

  security.rtkit.enable = true;
  environment.systemPackages = with pkgs; [
    pulseaudio
  ];

  # Looks like I need SOF firmware for some laptops
  hardware.firmware = with pkgs; [
    sof-firmware
  ];

  services = {
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      extraConfig = {
        pipewire = {
          "10-wtf-discord-fix" = {
            "context.properties" = {
              "default.clock.quantum" = 2048;
              "default.clock.min-quantum" = 1024;
              "default.clock.max-quantum" = 4096;
            };
          };
        };
        # Prevent any app to fuck up the mic volumes
        pipewire-pulse = {
          "99-disable-auto-gain-control" = {
            "pulse.rules" = [
              {
                actions = {
                  quirks = [
                    "block-source-volume"
                  ];
                };
                matches = [
                  {
                    "application.process.binary" = "~.*";
                  }
                ];
              }
            ];
          };
        };
      };
      wireplumber.extraConfig = {
        "50-logitech-zone-vibe-soft-mixer" = {
          "monitor.alsa.rules" = [
            {
              matches = [
                {
                  "device.name" = "alsa_card.usb-Logitech_Zone_Vibe_125_2342MH00B9W8-00";
                }
              ];
              actions = {
                update-props = {
                  # Bypass hardware mixer, use software volume instead.
                  # Prevents the headset firmware from resetting volume on reconnect/resume.
                  "api.alsa.soft-mixer" = true;
                };
              };
            }
          ];
        };
      };
    };

    # @Reference: Emit a new DBUS signal, if new sound device added
    # udev.extraRules = lib.mkMerge [
    # ''ACTION=="add",	SUBSYSTEM=="sound", ENV{ID_TYPE}=="audio", RUN+="${signal_script} org.custom.gurkan.sound_device_added"''
    # ''ACTION=="remove",	SUBSYSTEM=="sound", ENV{DEVPATH}=="*/card[0-9]", ENV{ID_TYPE}=="audio", RUN+="${signal_script} org.custom.gurkan.sound_device_removed"''
    # ];

    # Disable KEY_MICMUTE (scancode b002f) from Zone Vibe 125 headset.
    # The headset sends a toggle key event on mic flip but also handles mute in hardware,
    # causing double-toggle with the keyboard's XF86AudioMicMute binding.
    udev.extraHwdb = ''
      evdev:input:b0003v046Dp0AEE*
       KEYBOARD_KEY_b002f=reserved
    '';
  };
}
#  vim: set ts=2 sw=2 tw=0 et :

