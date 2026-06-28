{ lib, pkgs }:

{
  # Create a systemd oneshot service that manages the compose stack.
  mkSystemdService = groupName: grpCfg: composeFile: composeBin: runtimeService: hasFiles:
    let
      stateDir = grpCfg.stateDir;
      fileServiceDep = if hasFiles then "container-services-${groupName}-files.service" else null;
    in
    {
      description = "Container service group '${groupName}'";
      wantedBy = [ "multi-user.target" ];
      after = [ runtimeService "network-online.target" "agenix.service" ]
        ++ lib.optional hasFiles fileServiceDep;
      requires = [ runtimeService ]
        ++ lib.optional hasFiles fileServiceDep;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        TimeoutStopSec = grpCfg.timeoutStopSec;
        ExecStartPre = "${pkgs.coreutils}/bin/cp ${composeFile} ${stateDir}/compose.yml";
        ExecStart = "${composeBin} -p ${groupName} -f ${stateDir}/compose.yml up -d --remove-orphans";
        ExecStop = "${composeBin} -p ${groupName} -f ${stateDir}/compose.yml down";
      };
    };

  # Create a path unit that watches env files for changes.
  mkPathUnit = groupName: envFiles:
    lib.optionalAttrs (envFiles != [ ]) {
      "container-services-${groupName}-env-reload" = {
        description = "Watch env files for container service group '${groupName}'";
        pathConfig = {
          PathChanged = map toString envFiles;
          Unit = "container-services-${groupName}-env-reload.service";
        };
        wantedBy = [ "multi-user.target" ];
      };
    };

  # Create a service that restarts the compose stack when env files change.
  mkEnvReloadService = groupName:
    {
      "container-services-${groupName}-env-reload" = {
        description = "Restart container service group '${groupName}' on env file changes";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.systemd}/bin/systemctl restart container-services-${groupName}.service";
        };
      };
    };
}
