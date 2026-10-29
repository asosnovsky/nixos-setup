# sibli is ephemeral: root resets to this config on every start, so change
# things here (then rebuild the host), not inside the robot.
{ config, pkgs, ... }:
let
  robotoName = config.services.hermes-agent.environment.API_SERVER_MODEL_NAME;
in
{
  imports = [
    ./common.nix
    ./buzz.nix
  ];

  skyg.robot.buzz = {
    enable = true;
    homeChannel = "a8969cdc-7ba2-4e25-ae18-b898ab59003d";
  };

  services.hermes-agent = {
    extraPackages = [ pkgs.nodejs ];
    mcpServers.shortcut = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [ "-y" "@shortcut/mcp@latest" ];
      env.SHORTCUT_API_TOKEN = "\${SHORTCUT_API_KEY}";
    };
  };

  services.tailscale.enable = true;
  services.tailscale.openFirewall = true;
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  systemd.services.tailscale-login = {
    description = "Log in to Tailscale if needed";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" "tailscaled.service" ];
    requires = [ "tailscaled.service" ];
    path = [ config.services.tailscale.package pkgs.jq ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      EnvironmentFile = config.systemd.services.hermes-agent.serviceConfig.EnvironmentFile;
    };
    script = ''
      if [ -z "''${TS_AUTHKEY:-}" ]; then
        echo "No TS_AUTHKEY, skipping."
        exit 0
      fi
      # Retry: the daemon may not be ready yet. Failure is not fatal.
      for _ in 1 2 3 4 5 6; do
        state=""
        if out=$(tailscale status --json); then
          state=$(jq -r '.BackendState' <<<"$out") || state=""
        fi
        case "$state" in
          Running)
            echo "Already logged in."
            exit 0
            ;;
          NeedsLogin|Stopped)
            if tailscale up --auth-key="$TS_AUTHKEY" --hostname=ari-fwdesk-${robotoName}-bot; then
              echo "Logged in."
              exit 0
            fi
            ;;
        esac
        sleep 5
      done
      echo "Could not log in to Tailscale." >&2
    '';
  };
}
