# Buzz for a robot's Hermes: the `buzz` CLI and a profile for its key.
# Shared by this host's robots (copied into each under /etc/nixos/seed).
# Needs a Buzz identity in the robot's secret: `skyg buzz identity <robot>`.
{ config, lib, pkgs, ... }:
let
  cfg = config.skyg.robot.buzz;
  # Built from this repo; the robot gets a copy of pkgs/buzz-cli with this file.
  buzz-cli = pkgs.callPackage ../../../../pkgs/buzz-cli { };
in
{
  options.skyg.robot.buzz = {
    enable = lib.mkEnableOption "Buzz for this robot's Hermes";
    homeChannel = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "BUZZ_HOME_CHANNEL (not secret, so it lives here, not in the secret).";
    };
    profileName = lib.mkOption {
      type = lib.types.str;
      default = config.services.hermes-agent.environment.API_SERVER_MODEL_NAME or config.networking.hostName;
      defaultText = lib.literalExpression "the Hermes gateway model name, else the host name";
      description = "Name published for a new key that has no Buzz profile yet.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ buzz-cli ];

    # The Hermes service PATH has no system packages.
    services.hermes-agent.environment = {
      BUZZ_CLI_PATH = "${buzz-cli}/bin/buzz";
    } // lib.optionalAttrs (cfg.homeChannel != null) {
      BUZZ_HOME_CHANNEL = cfg.homeChannel;
    };

    # A new Buzz key has no profile, and Hermes won't connect without one.
    # Publish one at start if missing; the relay keeps it.
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
            if buzz users set-profile --name ${lib.escapeShellArg cfg.profileName}; then
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
  };
}
