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
      wants = [ "network-online.target" "remote-fs.target" ];
      after = [
        runtimeService
        "network-online.target"
        "agenix.service"
        "remote-fs.target"
      ]
      ++ lib.optional hasFiles fileServiceDep;
      requires = [ runtimeService ]
        ++ lib.optional hasFiles fileServiceDep;
      startLimitIntervalSec = 300; # 5 minutes window
      startLimitBurst = 6; # allow 6 failures before giving up
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = "15s";
        TimeoutStartSec = "120s";
        Type = "oneshot";
        RemainAfterExit = true;
        TimeoutStopSec = grpCfg.timeoutStopSec;
        ExecStartPre = "${pkgs.coreutils}/bin/cp ${composeFile} ${stateDir}/compose.yml";
        ExecStart = "${composeBin} -p ${groupName} -f ${stateDir}/compose.yml up -d --remove-orphans";
        ExecStop = "${composeBin} -p ${groupName} -f ${stateDir}/compose.yml down";
      };
    };

  # Create the update service + timer for a group's autoUpdate config.
  mkUpdateUnits = groupName: grpCfg: composeBin: runtimeBin:
    let
      auCfg = grpCfg.autoUpdate;
      stateDir = grpCfg.stateDir;
      unitName = "container-services-${groupName}-update";
      composeCmd = "${composeBin} -p ${groupName} -f ${stateDir}/compose.yml";
    in
    {
      services."${unitName}" = {
        description = "Pull latest images and recreate container service group '${groupName}'";
        after = [ "container-services-${groupName}.service" ];
        requires = [ "container-services-${groupName}.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart =
            [
              "${composeCmd} pull"
              "${composeCmd} up -d --remove-orphans"
            ]
            ++ lib.optional auCfg.pruneImages "${runtimeBin} image prune -f";
        };
      };
      timers."${unitName}" = {
        description = "Scheduled image update for container service group '${groupName}'";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = auCfg.onCalendar;
          RandomizedDelaySec = auCfg.randomizedDelaySec;
          Persistent = auCfg.persistent;
          Unit = "${unitName}.service";
        };
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
