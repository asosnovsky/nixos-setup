# sibli is ephemeral: root resets to this config on every start, so change
# things here (then rebuild the host), not inside the robot.
{ config, lib, pkgs, ... }:
let
  # The robot's own nixpkgs has no host overlay, so build it from the repo.
  # Fine for the seed build; a rebuild inside the robot can't see this path.
  buzz-cli = pkgs.callPackage ../../../../pkgs/buzz-cli { };
  # Buzz profile name: the Hermes name the host passes to the gateway.
  buzzName = config.services.hermes-agent.environment.API_SERVER_MODEL_NAME or "sibli";
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

  # Hermes's Buzz platform runs `buzz`; the service PATH has no system packages.
  services.hermes-agent.environment.BUZZ_CLI_PATH = "${buzz-cli}/bin/buzz";

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
      # Same secrets as Hermes (container credentials from the host).
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
          if buzz users set-profile --name ${lib.escapeShellArg buzzName}; then
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

  # Own tailnet machine. Needs allowTun = true on the host.
  # Log in once: sudo tailscale up (state is kept via persist on the host)
  services.tailscale.enable = true;
  services.tailscale.openFirewall = true;
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
}
