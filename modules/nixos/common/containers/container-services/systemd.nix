{ lib, pkgs }:

{
  # Create a systemd oneshot service that manages the compose stack.
  # `runtimePkg` is put on PATH because podman-compose shells out to `podman`.
  mkSystemdService = groupName: grpCfg: composeFile: overridesFile: composeBin: runtimeService: runtimePkg: hasFiles:
    let
      stateDir = grpCfg.stateDir;
      fileServiceDep = if hasFiles then "container-services-${groupName}-files.service" else null;
      composeFileArgs =
        if overridesFile != null
        then "-f ${stateDir}/compose.overrides.yml -f ${stateDir}/compose.yml"
        else "-f ${stateDir}/compose.yml";
    in
    {
      description = "Container service group '${groupName}'";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" "remote-fs.target" "container-networks.target" ];
      after = [
        runtimeService
        "container-networks.target"
        "network-online.target"
        "agenix.service"
        "remote-fs.target"
      ]
      ++ lib.optional hasFiles fileServiceDep;
      requires = [ runtimeService ]
        ++ lib.optional hasFiles fileServiceDep;
      path = [ runtimePkg pkgs.coreutils ];
      startLimitIntervalSec = 300; # 5 minutes window
      startLimitBurst = 6; # allow 6 failures before giving up
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = "15s";
        TimeoutStartSec = grpCfg.timeoutStartSec;
        Type = "oneshot";
        RemainAfterExit = true;
        TimeoutStopSec = grpCfg.timeoutStopSec;
        ExecStartPre =
          [ "${pkgs.coreutils}/bin/cp ${composeFile} ${stateDir}/compose.yml" ]
          ++ lib.optional (overridesFile != null)
            "${pkgs.coreutils}/bin/cp ${overridesFile} ${stateDir}/compose.overrides.yml";
        ExecStart = "${composeBin} -p ${groupName} ${composeFileArgs} up -d --remove-orphans";
        ExecStop = "${composeBin} -p ${groupName} ${composeFileArgs} down";
      };
    };

  # Create the update service + timer for a group's autoUpdate config.
  mkUpdateUnits = groupName: grpCfg: overridesFile: composeBin: runtimeBin: runtimePkg:
    let
      auCfg = grpCfg.autoUpdate;
      stateDir = grpCfg.stateDir;
      unitName = "container-services-${groupName}-update";
      composeFileArgs =
        if overridesFile != null
        then "-f ${stateDir}/compose.overrides.yml -f ${stateDir}/compose.yml"
        else "-f ${stateDir}/compose.yml";
      composeCmd = "${composeBin} -p ${groupName} ${composeFileArgs}";
    in
    {
      services."${unitName}" = {
        description = "Pull latest images and recreate container service group '${groupName}'";
        after = [ "container-services-${groupName}.service" ];
        requires = [ "container-services-${groupName}.service" ];
        path = [ runtimePkg pkgs.coreutils ];
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
