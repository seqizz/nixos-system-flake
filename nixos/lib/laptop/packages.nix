{ pkgs, config, lib, ... }:
{
  # Packages not needed in servers
  environment.systemPackages = with pkgs; [
    acpi
    geteltorito # for converting iso to img
    iw
    linuxPackages.cpupower
    lm_sensors
    powertop
    samba
    wirelesstools
  ];
}
