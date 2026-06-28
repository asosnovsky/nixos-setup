{ config, pkgs, lib, ... }:

let
  containersCfg = config.skyg.nixos.common.containers;
  cfg = config.skyg.nixos.common.container-services;

  isDocker = containersCfg.runtime == "docker";

  composeBin =
    if isDocker
    then "${pkgs.docker-compose}/bin/docker-compose"
    else "${pkgs.podman-compose}/bin/podman-compose";

  runtimeService =
    if isDocker then "docker.service" else "podman.service";

  # ── Compose document builder ─────────────────────────────────────────────

  # Build one compose service entry from a service config.
  # groupName is threaded in so the default network reference is correct.
  mkComposeService = groupName: _svcName: svcCfg:
    {
      image = svcCfg.image;
      restart = svcCfg.restart;
      networks =
        if svcCfg.networks == [ ]
        then [ groupName ]
        else svcCfg.networks;
    }
    // lib.optionalAttrs (svcCfg.command != [ ]) {
      command = svcCfg.command;
    }
    // lib.optionalAttrs (svcCfg.ports != [ ]) {
      ports = svcCfg.ports;
    }
    // lib.optionalAttrs (svcCfg.volumes != [ ]) {
      volumes = svcCfg.volumes;
    }
    // lib.optionalAttrs (svcCfg.environment != { }) {
      environment = svcCfg.environment;
    }
    // lib.optionalAttrs (svcCfg.environmentFiles != [ ]) {
      env_file = map builtins.toString svcCfg.environmentFiles;
    }
    // lib.optionalAttrs (svcCfg.dependsOn != [ ]) {
      depends_on = svcCfg.dependsOn;
    }
    // svcCfg.extraConfig;

  # Build the full compose document attrset for a group.
  mkComposeAttrs = groupName: grpCfg:
    let
      networks =
        if grpCfg.networks == { }
        then { "${groupName}" = { driver = "bridge"; }; }
        else grpCfg.networks;
    in
    {
      services = lib.mapAttrs (mkComposeService groupName) grpCfg.services;
      networks = networks;
    }
    // lib.optionalAttrs (grpCfg.volumes != [ ]) {
      volumes = lib.genAttrs grpCfg.volumes (_: { });
    }
    // grpCfg.extraConfig;

  # Render compose.yml to the Nix store.
  mkComposeFile = groupName: grpCfg:
    (pkgs.formats.yaml { }).generate "compose.yml"
      (mkComposeAttrs groupName grpCfg);

  # ── Systemd service builder ──────────────────────────────────────────────

  # Collect all env files from all services in a group.
  getAllEnvFiles = grpCfg:
    lib.concatLists
      (lib.attrValues
        (lib.mapAttrs (_: svcCfg: svcCfg.environmentFiles) grpCfg.services));

  mkSystemdService = groupName: grpCfg:
    let
      composeFile = mkComposeFile groupName grpCfg;
      stateDir = grpCfg.stateDir;
    in
    {
      description = "Container service group '${groupName}'";
      wantedBy = [ "multi-user.target" ];
      # agenix.service decrypts secrets before we try to read env_file paths
      after = [ runtimeService "network-online.target" "agenix.service" ];
      requires = [ runtimeService ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        TimeoutStopSec = grpCfg.timeoutStopSec;
        # Stage the store-rendered compose.yml into a stable, readable location
        ExecStartPre = "${pkgs.coreutils}/bin/cp ${composeFile} ${stateDir}/compose.yml";
        ExecStart = "${composeBin} -p ${groupName} -f ${stateDir}/compose.yml up -d --remove-orphans";
        ExecStop = "${composeBin} -p ${groupName} -f ${stateDir}/compose.yml down";
      };
    };

  # Create a path unit that triggers a restart when env files change.
  mkPathUnit = groupName: envFiles:
    lib.optionalAttrs (envFiles != [ ]) {
      "container-services-${groupName}-env-reload" = {
        description = "Watch env files for container service group '${groupName}'";
        pathConfig = {
          PathChanged = map builtins.toString envFiles;
          Unit = "container-services-${groupName}-env-reload.service";
        };
        wantedBy = [ "multi-user.target" ];
      };
    };

  # Service that restarts the compose stack when env files change.
  mkEnvReloadService = groupName:
    {
      "container-services-${groupName}-env-reload" = {
        description = "Restart container service group '${groupName}' on env file changes";
        serviceConfig = {
          Type = "oneshot";
          # Restart the compose stack
          ExecStart = "${pkgs.systemd}/bin/systemctl restart container-services-${groupName}.service";
        };
      };
    };

  enabledGroups = lib.filterAttrs (_: g: g.enable) cfg;

in
{
  # ── Option declarations ──────────────────────────────────────────────────

  options.skyg.nixos.common.container-services = lib.mkOption {
    description = ''
      Compose-style container service groups.

      Each group is rendered to a compose.yml in the Nix store, staged into
      its stateDir on activation, and managed by a single systemd oneshot unit:

          container-services-<group>.service

      See modules/nixos/common/containers/user-guide.md for full documentation.
    '';
    default = { };
    type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
      options = {

        enable = lib.mkEnableOption "this container service group" // { default = true; };

        stateDir = lib.mkOption {
          type = lib.types.str;
          default = "/var/lib/container-services/${name}";
          description = "Directory where the staged compose.yml lives at runtime.";
        };

        timeoutStopSec = lib.mkOption {
          type = lib.types.int;
          default = 120;
          description = "Seconds to wait for 'compose down' before forcibly killing containers.";
        };

        services = lib.mkOption {
          description = "Container services in this group (maps to compose services: block).";
          default = { };
          type = lib.types.attrsOf (lib.types.submodule {
            options = {

              image = lib.mkOption {
                type = lib.types.str;
                description = "Container image (registry/name:tag).";
              };

              command = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "Entrypoint command override (compose command:).";
              };

              ports = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                example = [ "8642:8642" ];
                description = "Port mappings in HOST:CONTAINER format.";
              };

              volumes = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                example = [ "/var/lib/hermes:/opt/data" ];
                description = "Volume mounts in src:dst[:opts] format.";
              };

              environment = lib.mkOption {
                type = lib.types.attrsOf lib.types.str;
                default = { };
                description = "Environment variables as key/value pairs.";
              };

              environmentFiles = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = ''
                  Paths to env files loaded by compose at runtime.
                  Accepts runtime paths such as agenix secret paths
                  (e.g. config.age.secrets.my-secret.path).
                  Changes to these files will trigger an automatic restart.
                '';
              };

              dependsOn = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "Sibling service names that must start first (compose depends_on:).";
              };

              restart = lib.mkOption {
                type = lib.types.str;
                default = "unless-stopped";
                description = "Compose restart policy.";
              };

              networks = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = ''
                  Networks to join. Empty list = attach to the group's
                  auto-created bridge network (named after the group).
                '';
              };

              extraConfig = lib.mkOption {
                type = lib.types.attrsOf lib.types.anything;
                default = { };
                description = ''
                  Free-form attrset merged directly into the compose service
                  block. Use this for keys not modelled above:
                  shm_size, cap_add, devices, healthcheck, etc.
                '';
              };

            };
          });
        };

        volumes = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Named volumes declared at the top level of the compose document.";
        };

        networks = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = { };
          description = ''
            Network definitions for the top-level compose networks: block.
            Empty = auto-create a bridge network named after the group.
          '';
        };

        extraConfig = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = { };
          description = "Free-form attrset merged into the top-level compose document.";
        };

      };
    }));
  };

  # ── Configuration ────────────────────────────────────────────────────────

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

    # Create each group's stateDir via tmpfiles so the cp in ExecStartPre succeeds.
    systemd.tmpfiles.rules =
      lib.mapAttrsToList
        (_: grpCfg: "d ${grpCfg.stateDir} 0750 root root -")
        enabledGroups;

    # One oneshot unit per group — manages the whole compose stack.
    systemd.services =
      lib.mapAttrs'
        (groupName: grpCfg:
          lib.nameValuePair
            "container-services-${groupName}"
            (mkSystemdService groupName grpCfg))
        enabledGroups
      // lib.foldAttrs lib.recursiveUpdate { } (
        lib.mapAttrsToList
          (groupName: grpCfg:
            mkEnvReloadService groupName)
          (lib.filterAttrs
            (_: grpCfg: getAllEnvFiles grpCfg != [ ])
            enabledGroups)
      );

    # Path units that watch env files and trigger restarts.
    systemd.paths =
      lib.foldAttrs lib.recursiveUpdate { } (
        lib.mapAttrsToList
          (groupName: grpCfg:
            mkPathUnit groupName (getAllEnvFiles grpCfg))
          enabledGroups
      );
  };
}
