{ pkgs, config, lib, ... }:
{
  # Packages not needed in servers
  environment.systemPackages = with pkgs; [
    acpi
    android-tools
    bpftools
    geteltorito # for converting iso to img
    ghostscript
    iw
    linuxPackages.cpupower
    lm_sensors
    mosh
    powertop
    rustup
    samba
    wirelesstools
    xxd
  ];
}
