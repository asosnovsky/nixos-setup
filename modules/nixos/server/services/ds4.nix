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
      (optionalString (tokens != null) "--tokens ${toString tokens}")
      (optionalString (threads != null) "--threads ${toString threads}")
      (optionalString (power != null) "--power ${toString power}")
      (optionalString (prefillChunk != null) "--prefill-chunk ${toString prefillChunk}")
      (optionalString (batchedSession != null) "--batched-session ${toString batchedSession}")
      (optionalString (mixedPrefillQuantum != null) "--mixed-prefill-quantum ${toString mixedPrefillQuantum}")
      (optionalString (vision != null) "--vision ${escapeShellArg vision}")
      (optionalString (trace != null) "--trace ${escapeShellArg trace}")
      (optionalString (kvDiskDir != null) "--kv-disk-dir ${escapeShellArg kvDiskDir}")
      (optionalString (kvDiskSpaceMb != null) "--kv-disk-space-mb ${toString kvDiskSpaceMb}")
      (optionalString (kvCacheMinTokens != null) "--kv-cache-min-tokens ${toString kvCacheMinTokens}")
      (optionalString (kvCacheColdMaxTokens != null) "--kv-cache-cold-max-tokens ${toString kvCacheColdMaxTokens}")
      (optionalString (kvCacheContinuedIntervalTokens != null) "--kv-cache-continued-interval-tokens ${toString kvCacheContinuedIntervalTokens}")
      (optionalString (kvCacheBoundaryTrimTokens != null) "--kv-cache-boundary-trim-tokens ${toString kvCacheBoundaryTrimTokens}")
      (optionalString (kvCacheBoundaryAlignTokens != null) "--kv-cache-boundary-align-tokens ${toString kvCacheBoundaryAlignTokens}")
      (optionalString kvCacheRejectDifferentQuant "--kv-cache-reject-different-quant")
      (optionalString (toolMemoryMaxIds != null) "--tool-memory-max-ids ${toString toolMemoryMaxIds}")
      (optionalString cors "--cors")
      (optionalString (gpuDevices != null) "--gpu-devices ${escapeShellArg gpuDevices}")
      (optionalString ssdStreaming "--ssd-streaming")
      (optionalString ssdStreamingCold "--ssd-streaming-cold")
      (optionalString (ssdStreamingCacheExperts != null) "--ssd-streaming-cache-experts ${escapeShellArg ssdStreamingCacheExperts}")
      (optionalString (ssdStreamingFullLayers != null) "--ssd-streaming-full-layers ${toString ssdStreamingFullLayers}")
      (optionalString (ssdStreamingPreloadExperts != null) "--ssd-streaming-preload-experts ${toString ssdStreamingPreloadExperts}")
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

      tokens = mkOption {
        description = "Default max output tokens when clients omit a limit.";
        default = null;
        example = 4096;
        type = types.nullOr types.int;
      };

      threads = mkOption {
        description = "Number of inference threads (default: CPU core count).";
        default = null;
        example = 16;
        type = types.nullOr types.int;
      };

      power = mkOption {
        description = "GPU duty-cycle target, 1..100 (default: 100).";
        default = null;
        example = 80;
        type = types.nullOr types.int;
      };

      prefillChunk = mkOption {
        description = "Graph prefill chunk size in tokens.";
        default = null;
        example = 4096;
        type = types.nullOr types.int;
      };

      batchedSession = mkOption {
        description = "Keep N resident sessions and batch decode-ready requests.";
        default = null;
        example = 4;
        type = types.nullOr types.int;
      };

      mixedPrefillQuantum = mkOption {
        description = "Prefill chunk size while generations are active (default: 128; GLM-5.3 minimum: 1024).";
        default = null;
        example = 128;
        type = types.nullOr types.int;
      };

      vision = mkOption {
        description = "Path to the vision encoder GGUF for the selected model.";
        default = null;
        example = "/var/lib/ds4/vision.gguf";
        type = types.nullOr types.str;
      };

      trace = mkOption {
        description = "Write prompts, cache decisions, output, and tool calls to this file.";
        default = null;
        example = "/var/lib/ds4/trace.log";
        type = types.nullOr types.str;
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

      kvCacheMinTokens = mkOption {
        description = "Do not save/load KV checkpoints shorter than this many tokens (default: 512).";
        default = null;
        example = 512;
        type = types.nullOr types.int;
      };

      kvCacheColdMaxTokens = mkOption {
        description = "Save cold first prompts up to this many tokens; 0 disables (default: 30000).";
        default = null;
        example = 30000;
        type = types.nullOr types.int;
      };

      kvCacheContinuedIntervalTokens = mkOption {
        description = "Save aligned continued frontiers every N tokens; 0 disables (default: 10000).";
        default = null;
        example = 10000;
        type = types.nullOr types.int;
      };

      kvCacheBoundaryTrimTokens = mkOption {
        description = "Trim tail tokens for cold boundary saves (default: 32).";
        default = null;
        example = 32;
        type = types.nullOr types.int;
      };

      kvCacheBoundaryAlignTokens = mkOption {
        description = "Align cold boundary saves to this multiple (default: 2048).";
        default = null;
        example = 2048;
        type = types.nullOr types.int;
      };

      kvCacheRejectDifferentQuant = mkOption {
        description = "Reject KV checkpoints written with different routed-expert quantization.";
        default = false;
        type = types.bool;
      };

      toolMemoryMaxIds = mkOption {
        description = "Exact tool-call IDs kept in RAM (default: 100000).";
        default = null;
        example = 100000;
        type = types.nullOr types.int;
      };

      cors = mkOption {
        description = "Enable CORS headers for browser-based clients.";
        default = false;
        type = types.bool;
      };

      gpuDevices = mkOption {
        description = "GPU device IDs for multi-GPU inference (e.g. '0,1').";
        default = null;
        example = "0,1";
        type = types.nullOr types.str;
      };

      ssdStreaming = mkOption {
        description = "Opt in to SSD-backed model streaming instead of full residency (Metal/CUDA/ROCm).";
        default = false;
        type = types.bool;
      };

      ssdStreamingCacheExperts = mkOption {
        description = "SSD streaming cache target: N requests dynamic expert slots; NGB also reserves two full prefill layers.";
        default = null;
        example = "64";
        type = types.nullOr types.str;
      };

      ssdStreamingCold = mkOption {
        description = "SSD streaming: skip the default popularity-based expert-cache preload.";
        default = false;
        type = types.bool;
      };

      ssdStreamingFullLayers = mkOption {
        description = "GLM Metal streaming: keep the first N routed layers fully resident (default: auto; 0 disables).";
        default = null;
        example = 8;
        type = types.nullOr types.int;
      };

      ssdStreamingPreloadExperts = mkOption {
        description = "SSD streaming: upfront popularity preload count (DeepSeek auto-seeds by default; GLM demand-fills unless set).";
        default = null;
        example = 128;
        type = types.nullOr types.int;
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

      autoStart = mkOption {
        description = ''
          Whether to start ds4-server automatically at boot.
          Set to false to only start it on demand via `systemctl start ds4-server`.
        '';
        default = true;
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
      wantedBy = lib.optionals cfg.autoStart [ "multi-user.target" ];

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
