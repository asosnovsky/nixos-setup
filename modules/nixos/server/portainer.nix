{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.skyg.nixos.server.portainer;

  # Kubernetes manifest for the Portainer Agent (without the EDGE_KEY secret —
  # that's created at runtime from the age secret).
  agentManifest = pkgs.writeText "portainer-agent-k8s.yml" ''
    apiVersion: v1
    kind: Namespace
    metadata:
      name: portainer
    ---
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: portainer-agent
      namespace: portainer
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: portainer-agent
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: cluster-admin
    subjects:
      - kind: ServiceAccount
        name: portainer-agent
        namespace: portainer
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: portainer-agent
      namespace: portainer
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: portainer-agent
      template:
        metadata:
          labels:
            app: portainer-agent
        spec:
          serviceAccountName: portainer-agent
          containers:
            - name: portainer-agent
              image: portainer/agent:2.45.0
              env:
                - name: EDGE
                  value: "1"
                - name: EDGE_INSECURE_POLL
                  value: "1"
                - name: EDGE_KEY
                  valueFrom:
                    secretKeyRef:
                      name: portainer-agent-edge-key
                      key: EDGE_KEY
                - name: EDGE_ID
                  valueFrom:
                    secretKeyRef:
                      name: portainer-agent-edge-key
                      key: EDGE_ID
                - name: KUBERNETES_POD_IP
                  valueFrom:
                    fieldRef:
                      fieldPath: status.podIP
              volumeMounts:
                - name: data
                  mountPath: /data
              livenessProbe:
                httpGet:
                  path: /health
                  port: 9001
              readinessProbe:
                httpGet:
                  path: /health
                  port: 9001
          volumes:
            - name: data
              emptyDir: {}
  '';
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

      k3s = {
        enable = mkEnableOption "deploy the Portainer Agent as a Kubernetes deployment on k3s";

        edgeKeySecretName = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            Name of the age secret containing the EDGE_KEY for the k3s agent.
            The corresponding age.secrets.<name>.file must be declared in the
            host file. Example: "portainer-agent-minipc3"
          '';
        };
      };
    };
  };

  config = mkIf cfg.enable {
    # Server mode — Docker container via container-services
    # Agent mode (Docker) — Docker container via container-services
    skyg.nixos.common.container-services.portainer = mkMerge [
      (mkIf (cfg.mode == "server") {
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
      })
      (mkIf (cfg.mode == "agent" && !cfg.agent.k3s.enable) {
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
      })
    ];

    # Agent mode — Kubernetes deployment on k3s
    systemd.services.portainer-agent-k3s = mkIf (cfg.mode == "agent" && cfg.agent.k3s.enable) {
      description = "Portainer Edge Agent on k3s";
      after = [ "k3s.service" ];
      wants = [ "k3s.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        Environment = "KUBECONFIG=/etc/rancher/k3s/k3s.yaml";
        ExecStart = "${pkgs.kubectl}/bin/kubectl apply -f ${agentManifest}";
      };
    };

    systemd.services.portainer-agent-k3s-secret = mkIf (cfg.mode == "agent" && cfg.agent.k3s.enable && cfg.agent.k3s.edgeKeySecretName != null) {
      description = "Portainer Edge Agent k3s secret";
      after = [ "k3s.service" ];
      wants = [ "k3s.service" ];
      before = [ "portainer-agent-k3s.service" ];
      wantedBy = [ "portainer-agent-k3s.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        Environment = "KUBECONFIG=/etc/rancher/k3s/k3s.yaml";
      };
      script = ''
        set -eu
        EDGE_KEY_FILE="${config.age.secrets.${cfg.agent.k3s.edgeKeySecretName}.path}"
        if [ ! -f "$EDGE_KEY_FILE" ]; then
          echo "EDGE_KEY file not found: $EDGE_KEY_FILE" >&2
          exit 1
        fi
        # shellcheck source=/dev/null
        . "$EDGE_KEY_FILE"
        ${pkgs.kubectl}/bin/kubectl create namespace portainer --dry-run=client -o yaml | ${pkgs.kubectl}/bin/kubectl apply -f -
        ${pkgs.kubectl}/bin/kubectl delete secret portainer-agent-edge-key --namespace portainer --ignore-not-found
        ${pkgs.kubectl}/bin/kubectl create secret generic portainer-agent-edge-key \
          --namespace portainer \
          --from-literal="EDGE_KEY=$EDGE_KEY" \
          --from-literal="EDGE_ID=$EDGE_ID" \
      '';
    };
  };
}
