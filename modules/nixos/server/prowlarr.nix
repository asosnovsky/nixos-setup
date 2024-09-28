{ config, lib, ... }:

let
  cfg = config.services.prowlarr;

in
{
  options = {
    services.prowlarr = {
      dataDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/prowlarr";
        description = "data directory for prowlarr";
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
