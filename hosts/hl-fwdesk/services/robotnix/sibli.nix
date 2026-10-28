# sibli is ephemeral: root resets to this config on every start, so change
# things here (then rebuild the host), not inside the robot.
{ config, lib, pkgs, ... }:
let
  buzz-cli = pkgs.callPackage ../../../../pkgs/buzz-cli { };
  robotoName = config.services.hermes-agent.environment.API_SERVER_MODEL_NAME;
in
{
  # The user has no password; ssh keys only.
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    htop
    claude-code
    devenv
    direnv
    (python3.withPackages (ps: [ ps.pip ]))
    nodejs
    docker-compose
    zellij
    buzz-cli
  ];
  nixpkgs.config.allowUnfree = true;

  # direnv: hook into bash so the repo's devenv shims work.
  programs.bash = {
    enable = true;
    interactiveShellInit = ''
      eval "$(direnv hook bash)"
    '';
  };

  services.hermes-agent.environment = {
    BUZZ_CLI_PATH = "${buzz-cli}/bin/buzz";
    BUZZ_HOME_CHANNEL = "a8969cdc-7ba2-4e25-ae18-b898ab59003d";
  };

  # A new Buzz key has no profile, and Hermes won't connect without one.
  # Publish one at start if missing; the relay keeps it across resets.
  systemd.services.buzz-profile = {
    description = "Publish the Buzz profile if missing";
    wantedBy = [ "multi-user.target" ];
    before = [ "hermes-agent.service" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    path = [ buzz-cli pkgs.jq ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "hermes";
      EnvironmentFile = config.systemd.services.hermes-agent.serviceConfig.EnvironmentFile;
    };
    script = ''
      if [ -z "''${BUZZ_PRIVATE_KEY:-}" ] || [ -z "''${BUZZ_RELAY_URL:-}" ]; then
        echo "No Buzz creds, skipping."
        exit 0
      fi
      # Retry: the relay may not be reachable yet. Failure is not fatal.
      for _ in 1 2 3 4 5; do
        n=""
        if out=$(buzz users get); then
          n=$(jq 'length' <<<"$out") || n=""
        fi
        if [ "$n" = "0" ]; then
          if buzz users set-profile --name ${lib.escapeShellArg robotoName}; then
            echo "Published Buzz profile."
            exit 0
          fi
        elif [ -n "$n" ]; then
          echo "Buzz profile exists."
          exit 0
        fi
        sleep 5
      done
      echo "Could not check or publish the Buzz profile." >&2
    '';
  };

  # Docker + compose. Needs allowDocker = true on the host.
  virtualisation.docker.enable = true;
  users.users.ari.extraGroups = [ "docker" ];
  users.users.hermes.extraGroups = [ "docker" ];

  # Own tailnet machine. Needs allowTun = true on the host.
  # Logs in by itself with TS_AUTHKEY from the robots-sibli secret.
  # State is kept via persist on the host, so this only matters once.
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
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
}
