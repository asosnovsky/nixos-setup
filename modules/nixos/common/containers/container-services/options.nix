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

        enable = lib.mkEnableOption "this container service group" // { default = false; };

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

        timeoutStartSec = lib.mkOption {
          type = lib.types.int;
          default = 120;
          description = "Seconds to wait for 'compose up -d' (image pulls included) before the unit is considered failed.";
        };

        composeFile = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "config.age.secrets.my-compose.path";
          description = ''
            Optional path to a ready-made compose file (e.g. an agenix-decrypted
            secret such as config.age.secrets.my-compose.path) to use as the
            group's compose.yml, instead of rendering one from services.

            When set, this group's services/files blocks are ignored; the
            external file must define services itself. However, networks/
            volumes/extraConfig set alongside composeFile ARE used: they're
            rendered into a base overrides file passed to compose via an
            earlier -f flag, so the composeFile is merged in as an override on
            top (compose's native multi-file merge — composeFile's own
            definitions win on any overlapping keys). Use this to keep a full
            service definition (NFS devices, images, env, etc.) out of version
            control while still deploying it through container-services, with
            shared/host-specific networks or volumes still declared in Nix.
          '';
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

              devices = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                example = [ "/dev/dri:/dev/dri" ];
                description = "Host device mappings in HOST:CONTAINER format (compose devices:).";
              };

              healthcheck = lib.mkOption {
                type = lib.types.attrsOf lib.types.anything;
                default = { };
                example = {
                  test = "curl --fail http://0.0.0.0:8096 || exit 1";
                  interval = "60s";
                  timeout = "20s";
                  start_period = "30s";
                };
                description = "Container healthcheck definition (compose healthcheck:).";
              };

              deploy = lib.mkOption {
                type = lib.types.attrsOf lib.types.anything;
                default = { };
                example = {
                  resources.reservations.devices = [
                    { driver = "cdi"; device_ids = [ "nvidia.com/gpu=all" ]; }
                  ];
                };
                description = "Deploy block (compose deploy:), e.g. GPU device reservations.";
              };

              restart = lib.mkOption {
                type = lib.types.str;
                default = "unless-stopped";
                description = "Compose restart policy.";
              };

              networks = lib.mkOption {
                type = lib.types.either (lib.types.listOf lib.types.str) (lib.types.attrsOf lib.types.anything);
                default = [ ];
                example = {
                  lan = { ipv4_address = "10.0.101.1"; };
                };
                description = ''
                  Networks to join. Empty list = attach to the group's
                  auto-created bridge network (named after the group).

                  Accepts either a plain list of network names, or an attrset
                  mapping network name -> per-network attrs (e.g.
                  ipv4_address, aliases) for compose's mapping form of the
                  networks: key -- needed to assign a static IP on a
                  macvlan/custom network.
                '';
              };

              dns = lib.mkOption {
                default = { };
                description = ''
                  Internal DNS names for this service. Folded into
                  skyg.dns.records, aggregated across hosts at the flake level,
                  and pushed to the router by `skyg openwrt`. Nothing is
                  configured on the host itself.
                '';
                type = lib.types.submodule {
                  options = {
                    names = lib.mkOption {
                      type = lib.types.listOf lib.types.str;
                      default = [ ];
                      example = [ "drawdb" ];
                      description = ''
                        DNS names for this service. Bare labels (no dot) are
                        suffixed with skyg.dns.domain, so [ "drawdb" ] becomes
                        drawdb.app.internal.
                      '';
                    };

                    ip = lib.mkOption {
                      type = lib.types.nullOr lib.types.str;
                      default = null;
                      description = ''
                        Address the names resolve to. When null (the default)
                        it is derived from this service's `networks` block --
                        which requires exactly one ipv4_address to be present.
                        Set explicitly for host-networked services or when the
                        service is attached to several networks.
                      '';
                    };

                    wildcard = lib.mkOption {
                      type = lib.types.bool;
                      default = false;
                      description = ''
                        Also resolve every subdomain of these names
                        (dnsmasq `address=/name/ip` instead of `host-record=`).
                      '';
                    };
                  };
                };
              };

              extra_hosts = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = ''
                  Additional host entries to add to the container's /etc/hosts file.
                '';
              };

              shm_size = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = ''
                  Size of the shared memory segment to allocate.
                '';
              };

              network_mode = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = ''
                  Network mode to use for the container.
                  Set to "host" to use the host's network stack.
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
                  block. Use this for keys not modelled above.
                '';
              };

            };
          });
        };

        volumes = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = { };
          example = {
            my-vol = {
              driver = "local";
              driver_opts = {
                type = "nfs";
                o = "addr=host,rw,nfsvers=4.0";
                device = ":/export/path";
              };
            };
            bare-vol = { };
          };
          description = ''
            Named volumes declared at the top level of the compose document
            (maps to the compose volumes: block). Key = volume name, value =
            volume definition (driver/driver_opts/etc.). Use an empty attrset
            for a default-driver named volume.
          '';
        };

        networks = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = { };
          description = ''
            Network definitions for the top-level compose networks: block.
            Empty = auto-create a bridge network named after the group.
          '';
        };

        autoUpdate = lib.mkOption {
          description = ''
            Scheduled image pull + recreate for this group. When enabled, a
            systemd timer periodically runs 'compose pull' followed by
            'compose up -d', so containers whose image changed are recreated.
          '';
          default = { };
          type = lib.types.submodule {
            options = {
              enable = lib.mkEnableOption "scheduled image pull + recreate for this group";

              onCalendar = lib.mkOption {
                type = lib.types.str;
                default = "weekly";
                example = "Sun 04:00";
                description = "systemd OnCalendar expression controlling update frequency.";
              };

              randomizedDelaySec = lib.mkOption {
                type = lib.types.int;
                default = 3600;
                description = ''
                  Random delay (seconds) added to each trigger, to spread load
                  across groups/hosts (systemd RandomizedDelaySec).
                '';
              };

              persistent = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Run a missed update on next boot (systemd Persistent).";
              };

              pruneImages = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Run 'image prune -f' after updating to reclaim dangling images.";
              };
            };
          };
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
