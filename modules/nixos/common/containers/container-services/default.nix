{ config, pkgs, lib, ... }:

let
  containersCfg = config.skyg.nixos.common.containers;
  cfg = config.skyg.nixos.common.container-services;

  containerLib = import ./lib.nix { inherit lib pkgs; };
  composeLib = import ./compose.nix { inherit lib; };
  filesLib = import ./files.nix { inherit lib pkgs containerLib; };
  systemdLib = import ./systemd.nix { inherit lib pkgs; };

  isDocker = containerLib.isDocker containersCfg.runtime;
  composeBin = containerLib.composeBin containersCfg.runtime;
  runtimeService = containerLib.runtimeService isDocker;
  runtimeBin = containerLib.runtimeBin isDocker;

  enabledGroups = lib.filterAttrs (_: g: g.enable) cfg;
  autoUpdateGroups = lib.filterAttrs (_: g: g.autoUpdate.enable) enabledGroups;
  optionsModule = import ./options.nix { inherit lib; };

in
{
  options = optionsModule.options;


  config = {
    assertions = lib.optionals (enabledGroups != { }) [
      {
        assertion = config.virtualisation.docker.enable or false
          || config.virtualisation.podman.enable or false;
        message = ''
          skyg.nixos.common.container-services: at least one container runtime
          must be enabled. Set skyg.nixos.common.containers.runtime (or enable
          virtualisation.docker / virtualisation.podman directly).
        '';
      }
    ];

    # Create tmpfiles rules for state dirs and file dirs
    systemd.tmpfiles.rules =
      (lib.mapAttrsToList
        (_: grpCfg: "d ${grpCfg.stateDir} 0750 root root -")
        enabledGroups)
      ++ (lib.mapAttrsToList
        (groupName: grpCfg:
          "d ${grpCfg.stateDir}/files 0755 root root -"
        )
        (lib.filterAttrs (_: grpCfg: filesLib.getAllFiles grpCfg != { }) enabledGroups)
      );

    # Systemd services: one compose unit + one env-reload unit per group with env files + one files unit per group with files
    systemd.services =
      lib.mapAttrs'
        (groupName: grpCfg:
          let
            fileVolumes = filesLib.mkFileVolumesForGroup groupName grpCfg;
            composeFile = composeLib.mkComposeFile pkgs groupName grpCfg fileVolumes;
            hasFiles = filesLib.getAllFiles grpCfg != { };
          in
          lib.nameValuePair
            "container-services-${groupName}"
            (systemdLib.mkSystemdService groupName grpCfg composeFile composeBin runtimeService hasFiles))
        enabledGroups
      // lib.foldAttrs lib.recursiveUpdate { } (
        lib.mapAttrsToList
          (groupName: grpCfg:
            systemdLib.mkEnvReloadService groupName)
          (lib.filterAttrs
            (_: grpCfg: containerLib.getAllEnvFiles grpCfg != [ ])
            enabledGroups)
      )
      // lib.foldAttrs lib.recursiveUpdate { } (
        lib.mapAttrsToList
          (groupName: grpCfg:
            filesLib.mkFilesService groupName grpCfg pkgs)
          (lib.filterAttrs
            (_: grpCfg: filesLib.getAllFiles grpCfg != { })
            enabledGroups)
      )
      // lib.mapAttrs'
        (groupName: grpCfg:
          let units = systemdLib.mkUpdateUnits groupName grpCfg composeBin runtimeBin;
          in lib.nameValuePair "container-services-${groupName}-update" units.services."container-services-${groupName}-update")
        autoUpdateGroups;

    # Path units: one per group with env files
    systemd.paths =
      lib.foldAttrs lib.recursiveUpdate { } (
        lib.mapAttrsToList
          (groupName: grpCfg:
            systemdLib.mkPathUnit groupName (containerLib.getAllEnvFiles grpCfg))
          enabledGroups
      );

    # Timers: one per group with autoUpdate enabled
    systemd.timers =
      lib.mapAttrs'
        (groupName: grpCfg:
          let units = systemdLib.mkUpdateUnits groupName grpCfg composeBin runtimeBin;
          in lib.nameValuePair "container-services-${groupName}-update" units.timers."container-services-${groupName}-update")
        autoUpdateGroups;
  };
}
