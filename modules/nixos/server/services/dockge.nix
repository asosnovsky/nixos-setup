{ config, lib, pkgs, ... }:

let
  cfg = config.skyg.nixos.server.services.dockge;
  volumeOptions = with lib; mkOption {
    type = types.submodule {
      options = {
        nfsServer = mkOption {
          type = types.str;
        };
        share = mkOption {
          type = types.str;
        };
      };
    };
  };
in
{
  options = {
    skyg.nixos.server.services.dockge = with lib; {
      enable = mkEnableOption
        "Enable Dockge";
      openFirewall = mkOption {
        description =
          "Open ports in the firewall for the dockge web interface.";
        default = false;
        type = types.bool;
      };
      port = mkOption {
        description = "The TCP port dockge will listen on.";
        default = 5001;
        type = types.port;
      };
      volumes = mkOption {
        type = types.submodule {
          options = {
            stacks = volumeOptions;
            data = volumeOptions;
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall =
      lib.mkIf cfg.openFirewall {
        allowedTCPPorts = [ cfg.port ];
        allowedUDPPorts = [ cfg.port ];
      };
    system.activationScripts = {
      dockge-create-volume-stacks = {
        text = ''
          ${pkgs.docker}/bin/docker volume create \
            --driver local \
            --opt type=nfs \
            --opt o=addr=${cfg.volumes.stacks.nfsServer},rw,nfsvers=4.0,nolock,hard,noatime \
            --opt device=:${cfg.volumes.stacks.share} \
            dockge-stacks
        '';
        deps = [ ];
      };
      dockge-create-volume-data = {
        text = ''
          ${pkgs.docker}/bin/docker volume create \
            --driver local \
            --opt type=nfs \
            --opt o=addr=${cfg.volumes.data.nfsServer},rw,nfsvers=4.0,nolock,hard,noatime \
            --opt device=:${cfg.volumes.data.share} \
            dockge-data
        '';
        deps = [ ];
      };
    };
    virtualisation.oci-containers = {
      containers = {
        dockge = {
          autoStart = true;
          image = "louislam/dockge:1";
          ports = [
            "${toString cfg.port}:5001"
          ];
          volumes = [
            "/var/run/docker.sock:/var/run/docker.sock"
            ''dockge-data:/app/data''
            ''dockge-stacks:/opt/stacks''
          ];
          environment = {
            DOCKGE_STACKS_DIR = "/opt/stacks";
          };
        };
      };
    };
  };
}
