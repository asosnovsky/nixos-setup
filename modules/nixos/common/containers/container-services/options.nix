{ lib }:

{
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

              files = lib.mkOption {
                type = lib.types.attrsOf lib.types.str;
                default = { };
                description = ''
                  Custom files to mount into the container.
                  Key = target path inside container (e.g. "/opt/data/config.yaml")
                  Value = file content as a string.
                  Files are written to /var/lib/container-services/<group>/files/ on the host
                  and bind-mounted read-only into the container at the specified paths.
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
}
