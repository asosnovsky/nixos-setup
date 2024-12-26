{ config, lib, pkgs, ... }:

let
  cfg = config.skyg.nixos.server.services.dockge;
in
{
  options = {
    skyg.nixos.server.services.dockge = {
      enable = lib.mkEnableOption
        "Enable Dockge";
      openFirewall = lib.mkOption {
        description =
          "Open ports in the firewall for the Audiobookshelf web interface.";
        default = false;
        type = lib.types.bool;
      };
      port = lib.mkOption {
        description = "The TCP port Audiobookshelf will listen on.";
        default = 5001;
        type = lib.types.port;
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
            --opt o=addr=terra1.lab.internal,rw,nfsvers=4.0,nolock,hard,noatime \
            --opt device=:/mnt/Data/apps/arrs/dockge/stacks \
            dockge-stacks
        '';
        deps = [ ];
      };
      dockge-create-volume-data = {
        text = ''
          ${pkgs.docker}/bin/docker volume create \
            --driver local \
            --opt type=nfs \
            --opt o=addr=terra1.lab.internal,rw,nfsvers=4.0,nolock,hard,noatime \
            --opt device=:/mnt/Data/apps/arrs/dockge/data \
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
