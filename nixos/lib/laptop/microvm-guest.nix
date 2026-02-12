# MicroVM guest packages and environment
# Base dev tools + claude-code always available.
# Additional packages can be installed at runtime via:
#   nix profile install nixpkgs#<pkg>
{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    unstable.claude-code
    git
    ripgrep
    fd
    curl
    jq
    gnumake
    gcc
  ];

  # nix CLI available for dynamic package installation inside VM
  nix.settings.experimental-features = ["nix-command" "flakes"];

  environment.variables = {
    CLAUDE_CONFIG_DIR = "/home/gurkan/.claude";
  };

  system.stateVersion = "24.05";
}
