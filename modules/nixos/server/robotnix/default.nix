# robotnix: self-managed NixOS nspawn containers ("robots").
# See ABOUTME.md in this folder for the design.
{ config, lib, ... }:
let
  inherit (lib) mkOption mkEnableOption types;
  cfg = config.skyg.nixos.server.robotnix;
  h = import ./helpers.nix { inherit config lib; };

  size = types.strMatching "[0-9]+[KMGT]";

  proto = mkOption {
    type = types.enum [
      "tcp"
      "udp"
    ];
    default = "tcp";
  };

  # One access tier. Used for `access.shared` and each robot's `access`.
  tier = types.submodule {
    options = {
      internet = mkOption {
        type = types.nullOr (
          types.enum [
            "all"
            "allowlist"
          ]
        );
        default = null;
        description = ''
          "all": the whole public internet (minus blocked entries).
          "allowlist": only allowedDomains / allowedCidrs.
          null: inherit (robot tier -> shared tier -> "all").
        '';
      };
      allowedDomains = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "github.com" ];
        description = "Domains (and their subdomains) reachable in allowlist mode.";
      };
      allowedCidrs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "140.82.112.0/20" ];
        description = "Public IPv4 ranges reachable in allowlist mode.";
      };
      blockedDomains = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Domains that never resolve. Applies in both modes.";
      };
      blockedCidrs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Public IPv4 ranges that are always dropped. Applies in both modes.";
      };
      lanAccess = mkOption {
        default = [ ];
        example = [
          {
            address = "10.0.101.3";
            port = 3000;
          }
        ];
        description = "LAN endpoints punched through the private-range drop.";
        type = types.listOf (
          types.submodule {
            options = {
              address = mkOption { type = types.str; };
              port = mkOption { type = types.port; };
              inherit proto;
            };
          }
        );
      };
      hostAccess = mkOption {
        default = [ ];
        example = [{ port = 11434; }];
        description = "Ports on this host the robot may reach.";
        type = types.listOf (
          types.submodule {
            options = {
              port = mkOption { type = types.port; };
              inherit proto;
            };
          }
        );
      };
      allowLan = mkOption {
        type = types.bool;
        default = false;
        description = "Open all private ranges. Almost always the wrong tool; use lanAccess.";
      };
    };
  };

  # Hermes options used by both the shared and the per-robot block.
  hermesSettings = mkOption {
    type = types.attrsOf types.anything;
    default = { };
    example = {
      model.provider = "openrouter";
    };
    description = "Hermes config.yaml settings. Shared and robot settings are deep-merged (robot wins).";
  };
  hermesEnvFiles = mkOption {
    type = types.listOf types.str;
    default = [ ];
    example = [ "/run/agenix/robots-shared" ];
    description = ''
      Host paths of KEY=value secret files (e.g. agenix). Passed to the robot
      as container credentials and loaded into Hermes's environment. Read at
      robot start: restart the robot after changing one.
    '';
  };

  # Gateway API / dashboard options. The top level sets the values; each
  # robot can override one (null = follow the top level).
  hermesService =
    { what
    , port
    , robot
    , enableText
    ,
    }:
    let
      opt =
        type: default: description:
        mkOption {
          type = if robot then types.nullOr type else type;
          default = if robot then null else default;
          description = if robot then "${description} null: follow hermes.${what}." else description;
        };
    in
    {
      enable = opt types.bool true enableText;
      port = opt types.port port "Port on the robot's address.";
      openFirewall = opt types.bool true "Open the port in the robot's firewall.";
    };
  hermesGateway =
    robot:
    hermesService {
      inherit robot;
      what = "gateway";
      port = 8642;
      enableText = ''
        Turn on the gateway's OpenAI-compatible API on all of the robot's
        addresses. The robot's secrets need API_SERVER_KEY, or it won't start.
      '';
    };
  hermesDashboard =
    robot:
    hermesService {
      inherit robot;
      what = "dashboard";
      port = 80;
      enableText = ''
        Run the Hermes dashboard on all of the robot's addresses. The robot's
        secrets need a login (HERMES_DASHBOARD_BASIC_AUTH_USERNAME,
        HERMES_DASHBOARD_BASIC_AUTH_PASSWORD_HASH and
        HERMES_DASHBOARD_BASIC_AUTH_SECRET), or the dashboard exits.
      '';
    };

  robot = types.submodule (
    { name, ... }:
    {
      options = {
        id = mkOption {
          type = types.ints.between 1 250;
          description = "Unique number per robot. Picks its DNS port (5300 + id).";
        };
        address = mkOption {
          type = types.str;
          example = "10.0.101.12";
          description = "The robot's own LAN IPv4 address.";
        };
        autoStart = mkOption {
          type = types.bool;
          default = true;
        };
        privateUsers = mkOption {
          type = types.bool;
          default = true;
          description = "Run in a user namespace (root inside != root on the host).";
        };
        user = mkOption {
          type = types.str;
          default = config.skyg.user.name;
          description = "Login user created in the robot.";
        };
        authorizedKeys = mkOption {
          type = types.listOf types.str;
          default = config.skyg.nixos.common.ssh-server.masterPubKeys;
          description = "SSH keys for the user and root in the robot.";
        };
        cpus = {
          min = mkOption {
            type = types.ints.positive;
            default = 1;
          };
          max = mkOption {
            type = types.ints.positive;
            default = 4;
          };
        };
        memory = {
          min = mkOption {
            type = size;
            default = "8G";
            description = "Protected memory (MemoryLow).";
          };
          max = mkOption {
            type = size;
            default = "16G";
            description = "Hard limit (MemoryMax).";
          };
          swapMax = mkOption {
            type = size;
            default = "1G";
          };
        };
        disk = {
          rootSize = mkOption {
            type = size;
            default = "100G";
            description = "Root image: the whole OS including /nix. Grows on restart if raised.";
          };
          homeSize = mkOption {
            type = size;
            default = "60G";
            description = "/home image. Grows on restart if raised.";
          };
        };
        ephemeral = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Reset root to a clean copy of the seed on every start. Only /home
            (and `persist`) survives. Changes go through seed.configuration on
            the host. Snapshots then cover /home only.
          '';
        };
        persist = mkOption {
          type = types.listOf (types.strMatching "/[^:[:space:]]+");
          default = [ ];
          example = [ "/var/lib/tailscale" ];
          description = ''
            Folders kept across resets. Stored in /home/.persist inside the
            home image and mounted at their usual path.
          '';
        };
        hermes = {
          enable = mkOption {
            type = types.nullOr types.bool;
            default = null;
            description = "Run Hermes in this robot. null: follow hermes.enable.";
          };
          name = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "Siblibot";
            description = ''
              Name the agent gives itself ("I am Siblibot, a Hermes-based
              agent"). Written to SOUL.md by the host on every boot. null keeps
              the stock Hermes identity.
            '';
          };
          settings = hermesSettings;
          environmentFiles = hermesEnvFiles;
          gateway = hermesGateway true;
          dashboard = hermesDashboard true;
        };
        allowDocker = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Allow the syscalls Docker needs (add_key, keyctl, bpf). Host side
            only: enable Docker in the robot's own config.
          '';
        };
        allowTun = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Pass /dev/net/tun into the robot (e.g. for tailscale). Host side
            only: enable tailscale in the robot's own config.
          '';
        };
        access = mkOption {
          type = tier;
          default = { };
          description = "This robot's own tier, added on top of access.shared.";
        };
        snapshots = {
          enable = mkOption {
            type = types.bool;
            default = true;
          };
          interval = mkOption {
            type = types.str;
            default = "hourly";
            description = "systemd calendar expression.";
          };
          keep = mkOption {
            type = types.ints.positive;
            default = 24;
            description = "Automatic snapshots to keep. Manual ones are never pruned.";
          };
        };
        git = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Track /etc/nixos in git on first install and auto-commit.";
          };
          remoteUrl = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "git@github.com:ari/myrobot.git";
            description = ''
              Origin for the flake repo, set on first install. null = no remote:
              the timer commits locally but never pushes.
            '';
          };
          userName = mkOption {
            type = types.str;
            default = "robotnix";
          };
          userEmail = mkOption {
            type = types.str;
            default = "robotnix@localhost";
          };
          interval = mkOption {
            type = types.str;
            default = "daily";
            description = "systemd calendar for the auto-commit (and push, if a remote is set) timer.";
          };
        };
        seed = {
          configuration = mkOption {
            type = types.path;
            default = ./seed/configuration.nix;
            description = ''
              The robot's starting configuration.nix. Copied into /etc/nixos on
              first install and on `robotnix reseed`; after that the robot owns it.
            '';
          };
          stateVersion = mkOption {
            type = types.str;
            default = lib.trivial.release;
          };
        };
      };
    }
  );
in
{
  imports = [
    ./network.nix
    ./robots.nix
  ];

  options.skyg.nixos.server.robotnix = {
    enable = mkEnableOption "robotnix self-managed NixOS containers";

    externalInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "enp191s0";
      description = "Host LAN uplink. Robots' LAN IPs are proxy-ARPed here.";
    };

    baseDir = mkOption {
      type = types.str;
      default = "/var/lib/robotnix";
      description = "Must be on btrfs. Each robot gets <baseDir>/<name> as its own subvolume.";
    };

    switch = {
      name = mkOption {
        type = types.str;
        default = "robotnix-br";
      };
      address = mkOption {
        type = types.str;
        default = "10.78.0.1";
        description = "Host address on the switch: robots' gateway and DNS.";
      };
      prefixLength = mkOption {
        type = types.int;
        default = 24;
      };
    };

    dnsUpstreams = mkOption {
      type = types.listOf types.str;
      default = [ config.skyg.internalNetworkingMap.appNetwork.gateway ];
      description = "Where the host's per-robot DNS forwards to.";
    };

    localDomains = mkOption {
      type = types.listOf types.str;
      default = [
        "app.internal"
        "lab.internal"
      ];
      description = "Always resolvable, even in allowlist mode (reaching them still needs lanAccess).";
    };

    access.shared = mkOption {
      type = tier;
      default = { };
      description = "Tier applied to every robot.";
    };

    hermes = {
      enable = mkEnableOption "a Hermes agent in every robot (robots can opt out)";
      settings = hermesSettings;
      environmentFiles = hermesEnvFiles;
      gateway = hermesGateway false;
      dashboard = hermesDashboard false;
    };

    robots = mkOption {
      type = types.attrsOf robot;
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions =
      let
        rs = h.robotList;
        dupes = f: lib.filter (v: lib.count (x: x == v) (map f rs) > 1) (lib.unique (map f rs));
        apps = config.skyg.internalNetworkingMap.apps;
      in
      [
        {
          assertion = cfg.externalInterface != null;
          message = "skyg.nixos.server.robotnix.externalInterface must be set.";
        }
        {
          assertion = dupes (r: r.id) == [ ];
          message = "robotnix: robot ids must be unique (dupes: ${toString (dupes (r: r.id))}).";
        }
        {
          assertion = dupes (r: r.address) == [ ];
          message = "robotnix: robot addresses must be unique (dupes: ${toString (dupes (r: r.address))}).";
        }
      ]
      ++ lib.concatMap
        (
          r:
          let
            clash = lib.attrNames (lib.filterAttrs (an: a: a.ip == r.address && an != r.name) apps);
            both = a: b: lib.intersectLists r.access.${a} r.access.${b};
          in
          [
            {
              assertion = builtins.match "[a-z][a-z0-9-]{0,11}" r.name != null;
              message = "robotnix: robot name '${r.name}' must be lowercase, start with a letter, max 12 chars.";
            }
            {
              assertion = clash == [ ];
              message = "robotnix: ${r.name}'s address ${r.address} is already used by app(s): ${toString clash}.";
            }
            {
              assertion = both "allowedDomains" "blockedDomains" == [ ];
              message = "robotnix: ${r.name} both allows and blocks: ${toString (both "allowedDomains" "blockedDomains")}.";
            }
            {
              assertion = both "allowedCidrs" "blockedCidrs" == [ ];
              message = "robotnix: ${r.name} both allows and blocks: ${toString (both "allowedCidrs" "blockedCidrs")}.";
            }
            {
              assertion = !(r.ephemeral && r.git.enable);
              message = "robotnix: ${r.name} is ephemeral, so git-sync can't work (fresh repo every start). Set git.enable = false.";
            }
            {
              assertion = lib.all (p: !(lib.hasPrefix "/home" p || lib.hasPrefix "/nix" p || p == "/")) r.persist;
              message = "robotnix: ${r.name}'s persist folders can't be /, or under /home or /nix.";
            }
            {
              assertion =
                let
                  g = r.hermes.gateway;
                  d = r.hermes.dashboard;
                in
                  !(r.hermes.enable && g.enable && d.enable && g.port == d.port);
              message = "robotnix: ${r.name}'s Hermes gateway and dashboard can't share port ${toString r.hermes.gateway.port}.";
            }
            {
              assertion = r.cpus.min <= r.cpus.max;
              message = "robotnix: ${r.name} cpus.min must be <= cpus.max.";
            }
            {
              assertion = h.toBytes r.memory.min <= h.toBytes r.memory.max;
              message = "robotnix: ${r.name} memory.min must be <= memory.max.";
            }
          ]
        )
        rs;
  };
}
