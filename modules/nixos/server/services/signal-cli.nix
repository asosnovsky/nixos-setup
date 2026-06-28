{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.skyg.nixos.server.services.signal-cli;
  skygUser = config.skyg.user;
in
{
  options = {
    skyg.nixos.server.services.signal-cli = {
      enable = mkEnableOption
        "signal-cli daemon in HTTP mode (backs the Hermes Signal adapter).";

      package = mkPackageOption pkgs "signal-cli" { };

      host = mkOption {
        description = "Address the signal-cli HTTP daemon binds to.";
        default = "127.0.0.1";
        example = "0.0.0.0";
        type = types.str;
      };

      port = mkOption {
        description = "TCP port the signal-cli HTTP daemon listens on.";
        default = 8080;
        type = types.port;
      };

      configDir = mkOption {
        description = ''
          signal-cli config/state directory. The Signal account must be linked
          into this directory once (interactively) before the daemon can start:

            sudo signal-cli --config <configDir> link -n "HermesAgent"
        '';
        default = "/var/lib/signal-cli";
        type = types.str;
      };

      account = mkOption {
        description = ''
          Signal account number in E.164 format (e.g. "+15551234567"). When
          null, the daemon reads SIGNAL_ACCOUNT from environmentFile instead.
        '';
        default = null;
        type = types.nullOr types.str;
      };

      environmentFile = mkOption {
        description = ''
          Path to an EnvironmentFile (e.g. an agenix-decrypted secret) that
          provides SIGNAL_ACCOUNT. Used when account is null. Avoids putting the
          phone number in the world-readable Nix store.
        '';
        default = null;
        type = types.nullOr types.path;
      };

      openFirewall = mkOption {
        description = "Open the HTTP port in the firewall.";
        default = false;
        type = types.bool;
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = cfg.account != null || cfg.environmentFile != null;
      message =
        "skyg.nixos.server.services.signal-cli: set either `account` or `environmentFile` (providing SIGNAL_ACCOUNT).";
    }];

    systemd.tmpfiles.rules = [ "d ${cfg.configDir} 0700 root root - -" ];
    environment.systemPackages = [ pkgs.signal-cli ];
    systemd.services.signal-cli-daemon = {
      description = "signal-cli daemon (HTTP) for the Hermes Signal adapter";

      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = skygUser.name;
        Environment = "JAVA_OPTS=--enable-native-access=ALL-UNNAMED";
        EnvironmentFile =
          mkIf (cfg.environmentFile != null) cfg.environmentFile;
        ExecStart = pkgs.writeShellScript "signal-cli-daemon-start" ''
          set -eu
          account=${if cfg.account != null then lib.escapeShellArg cfg.account else "\"\${SIGNAL_ACCOUNT:?SIGNAL_ACCOUNT is unset/empty in the env file}\""}
          export JAVA_OPTS="--enable-native-access=ALL-UNNAMED"
          exec ${cfg.package}/bin/signal-cli --config ${cfg.configDir} --account "$account" daemon --http ${cfg.host}:${toString cfg.port}
        '';
        Restart = "on-failure";
        RestartSec = 5;
        StartLimitBurst = 2;
      };
    };

    networking.firewall =
      mkIf cfg.openFirewall { allowedTCPPorts = [ cfg.port ]; };
  };
}
