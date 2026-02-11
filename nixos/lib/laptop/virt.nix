{
  config,
  pkgs,
  ...
}: {
  networking.nftables.enable = true;
  networking.firewall.trustedInterfaces = ["incusbr*" "docker0"];
  programs.dconf.enable = true;
  environment.systemPackages = with pkgs; [virt-manager];
  systemd.services.libvirtd.restartIfChanged = false;
}
