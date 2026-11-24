{ pkgs, ... }:
{
  # System-wide config in /etc/tmux.conf, so machines without Home Manager
  # (rocksteady) get the same setup as the laptops.
  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
    # battery substitutes its #{battery_*} placeholders in status-right when
    # it loads, so status-right has to be set before the plugins run.
    extraConfigBeforePlugins = builtins.readFile ./tmux.conf;
    plugins = with pkgs.tmuxPlugins; [
      sensible
      battery
      extrakto
    ];
  };
}
