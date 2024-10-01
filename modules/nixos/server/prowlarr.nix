{ config, pkgs, lib, ... }:

let
  cfg = config.skg.nixos.server.services.prowlarr;

in
{
  options = {
    skg.nixos.server.services.prowlarr = {
      enable = lib.mkEnableOption "Prowlarr, an indexer manager/proxy for Torrent trackers and Usenet indexers";

      package = lib.mkPackageOption pkgs "prowlarr" { };

      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Open ports in the firewall for the Prowlarr web interface.";
      };
      dataDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/prowlarr";
        description = "data directory for prowlarr";
      };
      user = lib.mkOption {
        type = lib.types.str;
        default = "prowlarr";
      };
      group = lib.mkOption {
        type = lib.types.str;
        default = "prowlarr";
      };
      port = lib.mkOption {
        type = lib.types.int;
        default = 9096;
        description = "Port for prowlarr";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.prowlarr = {
      description = "Prowlarr";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        Type = "simple";
        DynamicUser = true;
        StateDirectory = "prowlarr";
        ExecStart = "${lib.getExe cfg.package} -nobrowser -data=${cfg.dataDir}";
        Restart = "on-failure";
      };
      environment.HOME = "/var/empty";
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
    };
  };
}
