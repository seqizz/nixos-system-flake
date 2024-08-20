{
  config,
  pkgs,
  ...
}: {
  services = {
    printing.drivers = with pkgs; [
      hplipWithPlugin
      gutenprint
      splix
    ];
  };
  environment.systemPackages = with pkgs; [
    cifs-utils
  ];
}
