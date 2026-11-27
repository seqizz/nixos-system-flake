# sysman: one command for rebuilding, the runtime work/private switch,
# generation housekeeping and generation diffs. The logic lives in
# scripts/sysman, this module only hands it the facts that differ per machine.
{
  config,
  pkgs,
  ...
}:
let
  writeSubbedBin =
    (import ./helper-modules/writeSubbedBin.nix {
      pkgs = pkgs;
    }).writeSubbedBin;

  workSpecialisation = config.local.profiles.work.asSpecialisation;
  networkManager = config.networking.networkmanager.enable;

  myConfigBase = if config.local.profiles.server.enable then "/shared" else "/home/gurkan";

  settings = {
    flake_path = "${myConfigBase}/syncfolder/dotfiles/nixos-system-flake";
    hostname = config.networking.hostName;
    work_specialisation = workSpecialisation;
    network_manager = networkManager;
    nmcli = if networkManager then "${pkgs.networkmanager}/bin/nmcli" else null;
    nvd = "${pkgs.nvd}/bin/nvd";
    # Both belong to the profile switch, so a machine without the
    # specialisation does not pull them into its closure through here.
    awesome_client = if workSpecialisation then "${pkgs.awesome}/bin/awesome-client" else null;
    skillissue = if workSpecialisation then "${pkgs.skillissue}/bin/skillissue" else null;
  };
in
{
  environment.systemPackages = [
    # nix, sudo, nixos-rebuild and systemctl are looked up on PATH, because the
    # host's own nix is the one that matches the running daemon.
    # The jail toolbox needs no step in `sysman clean`: `llm-custody` expires
    # its leases and unpins the generations at every jail start, so whatever
    # the clean collects is already unreferenced.
    (writeSubbedBin {
      name = "sysman";
      src = ./scripts/sysman;
      python = pkgs.python3;
      config = pkgs.writeText "sysman.json" (builtins.toJSON settings);
    })
    # zsh picks completions up from share/zsh/site-functions of the system
    # profile.
    (pkgs.writeTextDir "share/zsh/site-functions/_sysman" (
      builtins.readFile ./scripts/sysman-completion.zsh
    ))
  ];
}
