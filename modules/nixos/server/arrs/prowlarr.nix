{ config, lib, pkgs, ... }:

let
  cfg = config.skyg.server.arrs.prowlarr;
  dataDir = "${config.skyg.server.arrs.rootDataDir}/prowlarr";
  configXMLFile = pkgs.writeTextFile {
    name = "config.xml";
    text = ''
      <Config>
        <LogLevel>info</LogLevel>
        <EnableSsl>False</EnableSsl>
        <Port>${toString(cfg.port)}</Port>
        <UrlBase></UrlBase>
        <BindAddress>*</BindAddress>
        <UpdateMechanism>BuiltIn</UpdateMechanism>
        <LaunchBrowser>False</LaunchBrowser>
        <Branch>main</Branch>
        <PostgresUser>prowlarr</PostgresUser>
        <PostgresPort>${toString(config.skyg.server.arrs.database.port)}</PostgresPort>
        <PostgresHost>0.0.0.0</PostgresHost>
        <PostgresMainDb>prowlarr</PostgresMainDb>
        <PostgresLogDb>prowlarr-log</PostgresLogDb>
        <InstanceName>SkyG Prowlarr</InstanceName>
        <AuthenticationMethod>External</AuthenticationMethod>
        <AuthenticationRequired>Enabled</AuthenticationRequired>
      </Config>
    '';
  };
in
{
  config = lib.mkIf cfg.enable {
    users.users.${cfg.user} = {
      uid = cfg.uid;
      isSystemUser = true;
      group = cfg.group;
    };
    users.groups.${cfg.group} = {
      gid = cfg.gid;
      members = [
        cfg.user
        config.skyg.user.name
      ];
    };
    users.groups.www-data.members = [
      cfg.user
    ];
    systemd.services.prowlarr = {
      description = "Prowlarr";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      preStart = ''
        ln -sfn "${dataDir}/config.xml" "${configXMLFile}"
      '';
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = dataDir;
        Type = "simple";
        DynamicUser = true;
        StateDirectory = "prowlarr";
        ExecStart = "${lib.getExe cfg.package} -nobrowser -data=${dataDir}";
        Restart = "on-failure";
      };
      environment.HOME = "/var/empty";
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
    };
  };
}
