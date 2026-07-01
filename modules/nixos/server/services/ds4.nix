{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.skyg.nixos.server.services.ds4;
  skygUser = config.skyg.user;

  # The ds4 package variant to use: ds4 (cpu), ds4-rocm, ds4-cuda.
  ds4Pkg = cfg.package;

  # Build the ds4-server command line from options.
  # optionalString returns "" when false; filter those out so we don't get
  # spurious leading/trailing whitespace in the final command line.
  serverArgs = with cfg;
    concatStringsSep " " (filter (x: x != "") [
      "-m ${escapeShellArg model}"

      "--host ${host}"
      "--port ${toString port}"

      (optionalString (ctx != null) "--ctx ${toString ctx}")
      (optionalString (threads != null) "--threads ${toString threads}")
      (optionalString (batchSize != null) "--batch-size ${toString batchSize}")
      (optionalString (kvDiskDir != null) "--kv-disk-dir ${escapeShellArg kvDiskDir}")
      (optionalString (kvDiskSpaceMb != null) "--kv-disk-space-mb ${toString kvDiskSpaceMb}")
      (optionalString noKvOffload "--no-kv-offload")
      (optionalString cors "--cors")
      (optionalString (gpuDeviceIds != null) "--gpu ${escapeShellArg gpuDeviceIds}")
    ]);
in
{
  options = {
    skyg.nixos.server.services.ds4 = {
      enable = mkEnableOption
        "ds4-server, the OpenAI/Anthropic/Responses-compatible HTTP API for DwarfStar (DeepSeek V4 Flash/PRO local inference).";

      package = mkPackageOption pkgs "ds4" {
        default = pkgs.ds4;
      };

      user = mkOption {
        description = "The user to run ds4-server as.";
        type = types.str;
        default = skygUser.name;
      };

      group = mkOption {
        description = "The group to run ds4-server as.";
        type = types.str;
        default = "users";
      };

      model = mkOption {
        description = "Path to the GGUF model file (ds4flash.gguf).";
        type = types.str;
        example = "/var/lib/ds4/ds4flash.gguf";
      };

      host = mkOption {
        description = "Address the ds4-server HTTP API binds to.";
        default = "127.0.0.1";
        example = "0.0.0.0";
        type = types.str;
      };

      port = mkOption {
        description = "TCP port the ds4-server HTTP API listens on.";
        default = 8000;
        type = types.port;
      };

      ctx = mkOption {
        description = "Maximum context length (number of tokens).";
        default = 100000;
        example = 100000;
        type = types.nullOr types.int;
      };

      threads = mkOption {
        description = "Number of inference threads (default: CPU core count).";
        default = null;
        example = 16;
        type = types.nullOr types.int;
      };

      batchSize = mkOption {
        description = "Token batch size for prompt processing.";
        default = null;
        example = 512;
        type = types.nullOr types.int;
      };

      kvDiskDir = mkOption {
        description = "Directory for KV cache disk offloading (persists across restarts).";
        default = null;
        example = "/var/lib/ds4/kv";
        type = types.nullOr types.str;
      };

      kvDiskSpaceMb = mkOption {
        description = "Maximum disk space for KV cache offloading in MB.";
        default = null;
        example = 8192;
        type = types.nullOr types.int;
      };

      noKvOffload = mkOption {
        description = "Disable KV cache offloading to disk entirely.";
        default = false;
        type = types.bool;
      };

      cors = mkOption {
        description = "Enable CORS headers for browser-based clients.";
        default = false;
        type = types.bool;
      };

      gpuDeviceIds = mkOption {
        description = "GPU device IDs for multi-GPU inference (e.g. '0,1').";
        default = null;
        example = "0,1";
        type = types.nullOr types.str;
      };

      environment = mkOption {
        description = ''
          Extra environment variables for the ds4-server process. Useful for GPU
          backends — e.g. ROCm Strix Halo needs HSA_ENABLE_SDMA=0.

          Example for ROCm on Strix Halo:
            { HSA_ENABLE_SDMA = "0"; }
        '';
        default = { };
        example = { HSA_ENABLE_SDMA = "0"; };
        type = types.attrsOf types.str;
      };

      openFirewall = mkOption {
        description = "Open the ds4-server port in the firewall.";
        default = false;
        type = types.bool;
      };

      extraArgs = mkOption {
        description = "Additional arguments to append to the ds4-server command line.";
        default = [ ];
        example = [ "--no-mmap" "--log-format" "json" ];
        type = types.listOf types.str;
      };

      extraServiceConfig = mkOption {
        description = "Extra systemd service unit config (e.g. SupplementaryGroups, TimeoutStopSec).";
        default = { };
        example = {
          SupplementaryGroups = [ "render" "video" ];
          TimeoutStopSec = 120;
        };
        type = types.attrsOf types.str;
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.model != "";
        message = "skyg.nixos.server.services.ds4: `model` must be set to a GGUF file path.";
      }
    ];

    # Ensure the ds4 package is available in the system closure (for manual use).
    environment.systemPackages = [ ds4Pkg ];

    systemd.services.ds4-server = {
      description = "ds4-server — DwarfStar local inference HTTP API (DeepSeek V4 Flash/PRO)";
      documentation = [
        "https://github.com/antirez/ds4"
        "https://github.com/antirez/ds4#readme"
      ];

      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;

        # Construct the ExecStart as a shell script so we can export env vars
        # that would otherwise be lost with a raw binary + Environment= (e.g.
        # ROCM_PATH, HSA_ENABLE_SDMA). Use writeShellScript for a clean script
        # in the store.
        ExecStart = pkgs.writeShellScript "ds4-server-start" ''
          set -eu
          ${concatStringsSep "\n" (mapAttrsToList (name: value: "export ${name}=${escapeShellArg value}") cfg.environment)}
          exec ${ds4Pkg}/bin/ds4-server ${serverArgs} ${escapeShellArgs cfg.extraArgs}
        '';

        Restart = "on-failure";
        RestartSec = 10;
        StartLimitBurst = 3;

        # Security hardening
        NoNewPrivileges = true;
        ProtectHome = true;
        ProtectSystem = "full";
        PrivateTmp = true;
        CapabilityBoundingSet = "";
        SystemCallFilter = "@system-service @resources";
      } // cfg.extraServiceConfig;

      # Create directories for KV cache and model storage if configured.
    };
    systemd.tmpfiles.rules =
      (optional (cfg.kvDiskDir != null) "d ${cfg.kvDiskDir} 0700 ${cfg.user} ${cfg.group} - -")
      ++ (optional (cfg.model != "" && hasPrefix "/var/lib/ds4" cfg.model) "d /var/lib/ds4 0700 ${cfg.user} ${cfg.group} - -");

    networking.firewall =
      mkIf cfg.openFirewall { allowedTCPPorts = [ cfg.port ]; };
  };
}
