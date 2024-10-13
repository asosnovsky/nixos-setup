{ config, lib, ... }:

let
  cfg = config.skyg.server.arrs.prowlarr;
in
{
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
