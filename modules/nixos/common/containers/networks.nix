{ config, lib, pkgs, ... }:

let
  cfg = config.skyg.nixos.common.containers;

  isDocker = cfg.runtime == "docker";
  runtimeBin = if isDocker then "${pkgs.docker}/bin/docker" else "${pkgs.podman}/bin/podman";
  runtimeService = if isDocker then "docker.service" else "podman.service";

  enabledNetworks = lib.filterAttrs (_: net: net.enable) cfg.networks;

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
  options.skyg.nixos.common.containers.networks = lib.mkOption {
    default = { };
    description = ''
      Container networks created on the host at boot, one systemd oneshot per
      network, independent of any compose project. This gives a single network
      that several container-services groups can share.

      Reference one from a container-services group through its computed
      `compose` attribute:

          networks.lan = config.skyg.nixos.common.containers.networks.lab.compose;

      Works with both docker and podman (see runtime).
    '';
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

  config = {
    # Always defined so container-services units can order themselves after it.
    systemd.targets.container-networks = {
      description = "Container networks";
      wantedBy = [ "multi-user.target" ];
    };

    systemd.services = lib.mkIf cfg.enable (lib.mapAttrs'
      (n: net: lib.nameValuePair "container-network-${n}" {
        description = "Create container network '${net.name}'";
        after = [ runtimeService "network-online.target" ];
        requires = [ runtimeService ];
        wantedBy = [ "container-networks.target" ];
        before = [ "container-networks.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        # Idempotent: reuse the network if it already exists.
        script = ''
          ${runtimeBin} network inspect ${net.name} >/dev/null 2>&1 \
            || ${runtimeBin} ${createArgs net}
        '';
      })
      enabledNetworks);
  };
}
