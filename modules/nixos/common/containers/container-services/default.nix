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
  # Put the runtime CLI on each unit's PATH (podman-compose shells out to `podman`).
  runtimePkg = if isDocker then pkgs.docker else pkgs.podman;

  enabledGroups = lib.filterAttrs (_: g: g.enable) cfg;
  autoUpdateGroups = lib.filterAttrs (_: g: g.autoUpdate.enable) enabledGroups;
  optionsModule = import ./options.nix { inherit lib; };

  # When composeFile is set, networks/volumes/extraConfig declared alongside it
  # are rendered as a base overrides file merged in via an earlier -f flag, so
  # the composeFile's own definitions win on any overlapping keys.
  # ---- internal DNS (skyg.dns) ----------------------------------------------
  # Every service with dns.names set contributes a record. The address is taken
  # from dns.ip when given, otherwise derived from the service's `networks`
  # mapping (the compose form `{ lan.ipv4_address = "10.0.101.2"; }`).
  serviceStaticIps = svcCfg:
    if builtins.isAttrs svcCfg.networks
    then lib.filter (v: v != null) (lib.mapAttrsToList (_: n: n.ipv4_address or null) svcCfg.networks)
    else [ ];

  dnsServices = lib.flatten (lib.mapAttrsToList
    (groupName: grpCfg: lib.mapAttrsToList
      (svcName: svcCfg: { inherit groupName svcName svcCfg; })
      (lib.filterAttrs (_: svcCfg: svcCfg.dns.names != [ ]) grpCfg.services))
    enabledGroups);

  dnsServiceIp = s:
    if s.svcCfg.dns.ip != null
    then s.svcCfg.dns.ip
    else
      let ips = serviceStaticIps s.svcCfg;
      in if lib.length ips == 1 then lib.head ips else null;

  mkOverridesFileFor = groupName: grpCfg:
    if grpCfg.composeFile != null
      && (grpCfg.networks != { } || grpCfg.volumes != { } || grpCfg.extraConfig != { })
    then composeLib.mkOverridesFile pkgs groupName grpCfg
    else null;

in
{
  options = optionsModule.options;


  config = {
    assertions =
      (lib.optionals (enabledGroups != { })
        [{
          assertion = config.virtualisation.docker.enable or false
          || config.virtualisation.podman.enable or false;
          message = ''
            skyg.nixos.common.container-services: at least one container runtime
            must be enabled. Set skyg.nixos.common.containers.runtime (or enable
            virtualisation.docker / virtualisation.podman directly).
          '';
        }])
      ++ lib.mapAttrsToList
        (name: grpCfg:
          {
            assertion = grpCfg.composeFile == null || grpCfg.services == { };
            message =
              "skyg.nixos.common.container-services.${name}: set either composeFile OR services, not both.";
          })
        enabledGroups
      ++ map
        (s: {
          assertion = dnsServiceIp s != null;
          message = ''
            skyg.nixos.common.container-services.${s.groupName}.services.${s.svcName}:
            dns.names is set but no address could be determined. Found
            ${toString (lib.length (serviceStaticIps s.svcCfg))} ipv4_address
            entries in `networks` (exactly one is required). Set dns.ip
            explicitly.
          '';
        })
        dnsServices;

    # Internal DNS records for services that asked for a name.
    skyg.dns.records = map
      (s: {
        ip = dnsServiceIp s;
        inherit (s.svcCfg.dns) names wildcard;
        source = "container-services/${s.groupName}/${s.svcName}";
      })
      (lib.filter (s: dnsServiceIp s != null) dnsServices);

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
            # An external compose file (e.g. an agenix secret) is used for
            # services; otherwise render one from the group's options.
            effectiveComposeFile =
              if grpCfg.composeFile != null
              then grpCfg.composeFile
              else composeLib.mkComposeFile pkgs groupName grpCfg fileVolumes;
            overridesFile = mkOverridesFileFor groupName grpCfg;
            hasFiles = grpCfg.composeFile == null && filesLib.getAllFiles grpCfg != { };
          in
          lib.nameValuePair
            "container-services-${groupName}"
            (systemdLib.mkSystemdService groupName grpCfg effectiveComposeFile overridesFile composeBin runtimeService runtimePkg hasFiles))
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
          let units = systemdLib.mkUpdateUnits groupName grpCfg (mkOverridesFileFor groupName grpCfg) composeBin runtimeBin runtimePkg;
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
          let units = systemdLib.mkUpdateUnits groupName grpCfg (mkOverridesFileFor groupName grpCfg) composeBin runtimeBin runtimePkg;
          in lib.nameValuePair "container-services-${groupName}-update" units.timers."container-services-${groupName}-update")
        autoUpdateGroups;
  };
}
