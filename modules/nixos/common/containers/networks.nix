{ config, lib, pkgs, ... }:

let
  cfg = config.skyg.nixos.common.containers;

  isDocker = cfg.runtime == "docker";
  runtimeBin = if isDocker then "${pkgs.docker}/bin/docker" else "${pkgs.podman}/bin/podman";
  runtimeService = if isDocker then "docker.service" else "podman.service";

  # Convert a lab network config to the generic network shape for createArgs
  mkNetwork = { driver, mode, parent, subnet, gateway, ipRange, internal, name }: {
    inherit driver subnet gateway ipRange internal name;
    driverOpts = { inherit parent; } // lib.optionalAttrs (mode != null) { inherit mode; };
  };

  # Collect all enabled networks (predefined + extra)
  labNetworks =
    lib.optional cfg.networks.macvlanLab.enable
      (mkNetwork {
        driver = "macvlan";
        mode = null;
        parent = cfg.networks.macvlanLab.parent;
        subnet = cfg.networks.macvlanLab.subnet;
        gateway = cfg.networks.macvlanLab.gateway;
        ipRange = cfg.networks.macvlanLab.ipRange;
        internal = cfg.networks.macvlanLab.internal;
        name = "macvlan-lab";
      })
    ++ lib.optional cfg.networks.ipvlanLab.enable
      (mkNetwork {
        driver = "ipvlan";
        mode = "l2";
        parent = cfg.networks.ipvlanLab.parent;
        subnet = cfg.networks.ipvlanLab.subnet;
        gateway = cfg.networks.ipvlanLab.gateway;
        ipRange = cfg.networks.ipvlanLab.ipRange;
        internal = cfg.networks.ipvlanLab.internal;
        name = "ipvlan-lab";
      });

  extraNetworks = lib.attrValues (lib.filterAttrs (_: net: net.enable) cfg.networks.extra);

  allNetworks = labNetworks ++ extraNetworks;

  createArgs = net:
    lib.concatStringsSep " " (
      [ "network" "create" "--driver" net.driver ]
      ++ lib.mapAttrsToList (k: v: "--opt ${k}=${v}") net.driverOpts
      ++ lib.optional (net.subnet != null) "--subnet ${net.subnet}"
      ++ lib.optional (net.gateway != null) "--gateway ${net.gateway}"
      ++ lib.optional (net.ipRange != null) "--ip-range ${net.ipRange}"
      ++ lib.optional net.internal "--internal"
      ++ [ net.name ]
    );
in
{
  options.skyg.nixos.common.containers.networks = {
    macvlanLab = lib.mkOption {
      default = { };
      description = "Predefined macvlan lab network (driver = macvlan).";
      type = lib.types.submodule ({
        options = {
          enable = lib.mkEnableOption "macvlan lab network" // { default = false; };

          parent = lib.mkOption {
            type = lib.types.str;
            description = "Parent interface (e.g. eno1).";
            example = "eno1";
          };

          subnet = lib.mkOption {
            type = lib.types.str;
            default = "10.0.0.0/16";
            description = "IPv4 subnet.";
          };

          gateway = lib.mkOption {
            type = lib.types.str;
            default = "10.0.0.1";
            description = "IPv4 gateway.";
          };

          ipRange = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "IPv4 range for dynamic address allocation (--ip-range).";
          };

          internal = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Restrict the network to internal traffic (--internal).";
          };

          compose = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            readOnly = true;
            description = ''
              Computed compose `networks:` entry (external) for referencing this
              network from a container-services group.
            '';
          };
        };

        config.compose = {
          name = "macvlan-lab";
          external = true;
        };
      });
    };

    ipvlanLab = lib.mkOption {
      default = { };
      description = "Predefined ipvlan lab network (driver = ipvlan, mode = l2).";
      type = lib.types.submodule ({
        options = {
          enable = lib.mkEnableOption "ipvlan lab network" // { default = false; };

          parent = lib.mkOption {
            type = lib.types.str;
            description = "Parent interface (e.g. eno1).";
            example = "eno1";
          };

          subnet = lib.mkOption {
            type = lib.types.str;
            default = "10.0.0.0/16";
            description = "IPv4 subnet.";
          };

          gateway = lib.mkOption {
            type = lib.types.str;
            default = "10.0.0.1";
            description = "IPv4 gateway.";
          };

          ipRange = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "IPv4 range for dynamic address allocation (--ip-range).";
          };

          internal = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Restrict the network to internal traffic (--internal).";
          };

          compose = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            readOnly = true;
            description = ''
              Computed compose `networks:` entry (external) for referencing this
              network from a container-services group.
            '';
          };
        };

        config.compose = {
          name = "ipvlan-lab";
          external = true;
        };
      });
    };

    extra = lib.mkOption {
      default = { };
      description = "Additional custom container networks (generic attrset).";
      type = lib.types.attrsOf (lib.types.submodule ({ name, config, ... }: {
        options = {
          enable = lib.mkEnableOption "creating this container network" // { default = true; };

          name = lib.mkOption {
            type = lib.types.str;
            default = name;
            description = "Runtime name of the network.";
          };

          driver = lib.mkOption {
            type = lib.types.str;
            default = "bridge";
            example = "macvlan";
            description = "Network driver.";
          };

          driverOpts = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
            example = { parent = "eno1"; };
            description = "Driver options (--opt key=value), e.g. the macvlan parent interface.";
          };

          subnet = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "IPv4 subnet (--subnet).";
          };

          gateway = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "IPv4 gateway (--gateway).";
          };

          ipRange = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "IPv4 range for dynamic address allocation (--ip-range).";
          };

          internal = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Restrict the network to internal traffic (--internal).";
          };

          compose = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            readOnly = true;
            description = ''
              Computed compose `networks:` entry (external) for referencing this
              network from a container-services group.
            '';
          };
        };

        config.compose = {
          name = config.name;
          external = true;
        };
      }));
    };
  };

  config = {
    # Always defined so container-services units can order themselves after it.
    systemd.targets.container-networks = {
      description = "Container networks";
      wantedBy = [ "multi-user.target" ];
    };

    systemd.services = lib.mkIf (cfg.enable && allNetworks != [ ]) {
      container-networks-setup = {
        description = "Create configured container networks";
        after = [ runtimeService "network-online.target" ];
        requires = [ runtimeService ];
        wantedBy = [ "container-networks.target" ];
        before = [ "container-networks.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          ${lib.concatStringsSep "\n" (map (net: ''
            ${runtimeBin} network inspect ${net.name} >/dev/null 2>&1 \
              || ${runtimeBin} ${createArgs net}
          '') allNetworks)}
        '';
      };
    };
  };
}
