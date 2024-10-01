{ config, lib, ... }:
let
  cfg = config.skyg.server.db;
  dbPort = 5432;
in
{
  options = {
    skyg.server.db = {
      enable = lib.mkEnableOption
        "Enable DB Store";
      openFirewall = lib.mkEnableOption
        "Open Firewall ports for db port";lib.mkIf cfg.openFirewall
    };
  };
  config = lib.mkIf cfg.enable {
    networking.firewall.allowedUDPPorts = lib.mkIf cfg.openFirewall [ dbPort ];
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ dbPort ];
    services.postgresql = {
      enable = true;
      settings.port = dbPort;
      dataDir = "";
    };
  };
}
