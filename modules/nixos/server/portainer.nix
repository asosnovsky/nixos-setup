{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.skyg.nixos.server.portainer;
in
{
  options.skyg.nixos.server.portainer = {
    enable = mkEnableOption "Portainer container management UI";

    mode = mkOption {
      type = types.enum [ "server" "agent" ];
      default = "agent";
      description = ''
        Whether to run the Portainer server (management UI) or an Edge agent.
      '';
    };

    server = {
      ip = mkOption {
        type = types.str;
        default = "10.0.101.241";
        description = "Static IP on the ipvlan lab network for the server container.";
      };

      dnsName = mkOption {
        type = types.str;
        default = "portainer";
        description = ''
          Internal DNS name for the server. The app.internal suffix is added
          automatically by the DNS module.
        '';
      };

      tls = {
        enable = mkEnableOption "TLS with a lab CA certificate for the Portainer server";

        cert = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            Content of the TLS certificate in PEM format. Set to the output of
            builtins.readFile on the lab CA leaf cert committed in configs/pki/.
            Run `skyg ca issue <domain> --for <host>` first to create it.
            Example: builtins.readFile ../../configs/pki/portainer.app.internal.crt
          '';
        };

        keySecretName = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            Name of the age secret containing the TLS private key.
            Created by `skyg ca issue <domain> --for <host>`.
            The corresponding age.secrets.<name>.file must be declared
            in the host file.
            Example: "portainer-tls-key"
          '';
        };
      };
    };

    agent = {
      edgeKeySecretName = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Name of the age secret (without the secrets/ prefix or .age suffix)
          containing the EDGE_KEY for this agent. The corresponding
          age.secrets.<name>.file must be declared in the host file.
          Example: "portainer-agent-minipc1"
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    skyg.nixos.common.container-services.portainer =
      if cfg.mode == "server"
      then {
        enable = true;
        autoUpdate.enable = true;
        services.portainer = {
          image = "portainer/portainer-ce:lts";
          volumes =
            [ "/var/run/docker.sock:/var/run/docker.sock" "portainer_data:/data" ]
              ++ lib.optional (cfg.server.tls.enable && cfg.server.tls.keySecretName != null)
              "${config.age.secrets.${cfg.server.tls.keySecretName}.path}:/certs/key.pem:ro";
          networks.lan.ipv4_address = cfg.server.ip;
          dns.names = [ cfg.server.dnsName ];
        }
        // lib.optionalAttrs cfg.server.tls.enable {
          files."/certs/cert.pem" = cfg.server.tls.cert;
          environment = {
            PORTAINER_HTTP_ENABLED = "true";
            PORTAINER_SSL = "true";
            PORTAINER_SSLCERT = "/certs/cert.pem";
            PORTAINER_SSLKEY = "/certs/key.pem";
            PORTAINER_TUNNEL_PORT = "8000";
          };
        };
        volumes.portainer_data = {
          name = "portainer_data";
        };
        networks.lan = config.skyg.nixos.common.containers.networks.ipvlanLab.compose;
      }
      else {
        enable = true;
        autoUpdate.enable = true;
        services.agent = {
          image = "portainer/agent:2.45.0";
          volumes = [
            "/var/run/docker.sock:/var/run/docker.sock"
            "/var/lib/docker/volumes:/var/lib/docker/volumes"
            "portainer_agent_data:/data"
          ];
          environmentFiles = lib.optional (cfg.agent.edgeKeySecretName != null)
            config.age.secrets.${cfg.agent.edgeKeySecretName}.path;
          environment = {
            EDGE_INSECURE_POLL = "1";
            EDGE = "1";
          };
        };
        volumes.portainer_agent_data = {
          name = "portainer_data";
        };
      };
  };
}
