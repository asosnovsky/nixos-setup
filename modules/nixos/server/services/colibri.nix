{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.skyg.nixos.server.services.colibri;
  skygUser = config.skyg.user;

  # The colibri package variant to use: colibri (cpu), colibri-rocm.
  colibriPkg = cfg.package;

  # Build the `coli serve` command line from options.
  # optionalString returns "" when false; filter those out so we don't get
  # spurious leading/trailing whitespace in the final command line.
  serverArgs = with cfg;
    concatStringsSep " " (
      filter (x: x != "") [
        "--model ${escapeShellArg model}"
        "--host ${escapeShellArg host}"
        "--port ${toString port}"

        (optionalString (modelId != null) "--model-id ${escapeShellArg modelId}")
        (optionalString (ram != null) "--ram ${toString ram}")
        (optionalString (ctx != null) "--ctx ${toString ctx}")
        (optionalString (cap != null) "--cap ${toString cap}")
        "--ngen ${toString ngen}"
        (optionalString (topp != null) "--topp ${toString topp}")
        (optionalString (topk != null) "--topk ${toString topk}")
        (optionalString (temp != null) "--temp ${toString temp}")
        (optionalString (policy != null) "--policy ${policy}")
        (optionalString (gpu != null) "--gpu ${escapeShellArg gpu}")
        (optionalString (vram != null) "--vram ${toString vram}")
        "--max-queue ${toString maxQueue}"
        "--queue-timeout ${toString queueTimeout}"
        "--kv-slots ${toString kvSlots}"
      ]
      ++ map (o: "--cors-origin ${escapeShellArg o}") corsOrigins
      ++ map (h: "--allowed-host ${escapeShellArg h}") allowedHosts
    );
in
{
  options = {
    skyg.nixos.server.services.colibri = {
      enable = mkEnableOption
        "colibri-serve, the OpenAI-compatible HTTP API for colibrì (GLM-5.2/OLMoE local inference).";

      package = mkPackageOption pkgs "colibri" {
        default = pkgs.colibri;
      };

      user = mkOption {
        description = "The user to run coli serve as.";
        type = types.str;
        default = skygUser.name;
      };

      group = mkOption {
        description = "The group to run coli serve as.";
        type = types.str;
        default = "users";
      };

      model = mkOption {
        description = "Path to the (converted) model directory.";
        type = types.str;
        example = "/nvme/glm52_i4";
      };

      modelMirror = mkOption {
        description = ''
          Second copy of the model on another drive: expert reads are split
          across both SSDs. `coli` only reads this via the COLI_MODEL_MIRROR
          environment variable, so it's exported rather than passed as a flag.
        '';
        default = null;
        example = "/nvme2/glm52_i4";
        type = types.nullOr types.str;
      };

      diskWeights = mkOption {
        description = "Primary,mirror disk bandwidth ratio (e.g. \"9,3\"); default is measured at startup. Exported as COLI_DISK_WEIGHTS.";
        default = null;
        example = "9,3";
        type = types.nullOr types.str;
      };

      host = mkOption {
        description = "Address the coli serve HTTP API binds to.";
        default = "127.0.0.1";
        example = "0.0.0.0";
        type = types.str;
      };

      port = mkOption {
        description = "TCP port the coli serve HTTP API listens on.";
        default = 8000;
        type = types.port;
      };

      modelId = mkOption {
        description = "Model name reported by the OpenAI-compatible API (default: derived from the model's architecture).";
        default = null;
        example = "glm-5.2-colibri";
        type = types.nullOr types.str;
      };

      apiKeyFile = mkOption {
        description = ''
          Path to a file containing the bearer token clients must send. Read at
          service start and exported as COLI_API_KEY (never passed as a CLI
          argument, so it doesn't show up in `ps`). Leave null to run without
          authentication (fine for host-only binding on 127.0.0.1).
        '';
        default = null;
        example = "/run/agenix/colibri-api-key";
        type = types.nullOr types.path;
      };

      ram = mkOption {
        description = "RAM budget in GB (0 or null = auto: the engine uses ~88% of available RAM).";
        default = null;
        example = 64;
        type = types.nullOr types.int;
      };

      ctx = mkOption {
        description = "Maximum context length (number of tokens; null = auto).";
        default = null;
        example = 32768;
        type = types.nullOr types.int;
      };

      cap = mkOption {
        description = "Cache slots per layer (null = auto).";
        default = null;
        example = 4;
        type = types.nullOr types.int;
      };

      ngen = mkOption {
        description = "Maximum response tokens (a safety net; stop tokens usually end generation first).";
        default = 1024;
        type = types.int;
      };

      topp = mkOption {
        description = "Adaptive expert top-p (null = engine default).";
        default = null;
        example = 0.9;
        type = types.nullOr types.float;
      };

      topk = mkOption {
        description = "Fixed expert top-k (null = engine default).";
        default = null;
        type = types.nullOr types.int;
      };

      temp = mkOption {
        description = "Sampling temperature (0 = greedy; null = engine default, nucleus ~0.95).";
        default = null;
        example = 0.7;
        type = types.nullOr types.float;
      };

      policy = mkOption {
        description = "Resource policy. Explicit topk/topp still override it.";
        default = null;
        type = types.nullOr (types.enum [ "quality" "balanced" "experimental-fast" ]);
      };

      gpu = mkOption {
        description = "GPU device selection: \"auto\", \"none\", or a device list such as \"0,1\".";
        default = null;
        example = "auto";
        type = types.nullOr types.str;
      };

      vram = mkOption {
        description = "Total VRAM budget in GB (null = auto).";
        default = null;
        example = 24;
        type = types.nullOr types.int;
      };

      maxQueue = mkOption {
        description = "Maximum queued requests before the API rejects new ones.";
        default = 8;
        type = types.int;
      };

      queueTimeout = mkOption {
        description = "Seconds a request may wait in queue before timing out.";
        default = 300;
        type = types.int;
      };

      kvSlots = mkOption {
        description = "KV cache slots (non-GLM architectures currently support exactly 1).";
        default = 1;
        type = types.int;
      };

      corsOrigins = mkOption {
        description = "Origins allowed by CORS (repeatable). Empty = CORS disabled.";
        default = [ ];
        example = [ "https://chat.example.com" ];
        type = types.listOf types.str;
      };

      allowedHosts = mkOption {
        description = "Additional Host headers accepted by the DNS-rebinding guard (repeatable).";
        default = [ ];
        example = [ "colibri.lan" ];
        type = types.listOf types.str;
      };

      environment = mkOption {
        description = ''
          Extra environment variables for the coli serve process. Useful for
          GPU backends — e.g. ROCm Strix Halo may need HSA_OVERRIDE_GFX_VERSION.

          Example for ROCm on Strix Halo:
            { HSA_OVERRIDE_GFX_VERSION = "11.0.2"; }
        '';
        default = { };
        example = { HSA_OVERRIDE_GFX_VERSION = "11.0.2"; };
        type = types.attrsOf types.str;
      };

      openFirewall = mkOption {
        description = "Open the coli serve port in the firewall.";
        default = false;
        type = types.bool;
      };

      extraArgs = mkOption {
        description = "Additional arguments to append to the coli serve command line.";
        default = [ ];
        example = [ "--auto-tier" ];
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
        message = "skyg.nixos.server.services.colibri: `model` must be set to a model directory path.";
      }
    ];

    # Ensure the colibri package is available in the system closure (for manual use).
    environment.systemPackages = [ colibriPkg ];

    systemd.services.colibri-serve = {
      description = "coli serve — colibrì local inference HTTP API (GLM-5.2/OLMoE)";
      documentation = [
        "https://github.com/JustVugg/colibri"
        "https://github.com/JustVugg/colibri#readme"
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
        # COLI_MODEL_MIRROR, COLI_API_KEY read from a file). Use
        # writeShellScript for a clean script in the store.
        ExecStart = pkgs.writeShellScript "colibri-serve-start" ''
          set -eu
          ${optionalString (cfg.modelMirror != null) "export COLI_MODEL_MIRROR=${escapeShellArg cfg.modelMirror}"}
          ${optionalString (cfg.diskWeights != null) "export COLI_DISK_WEIGHTS=${escapeShellArg cfg.diskWeights}"}
          ${optionalString (cfg.apiKeyFile != null) ''export COLI_API_KEY="$(cat ${escapeShellArg cfg.apiKeyFile})"''}
          ${concatStringsSep "\n" (mapAttrsToList (name: value: "export ${name}=${escapeShellArg value}") cfg.environment)}
          exec ${colibriPkg}/bin/coli serve ${serverArgs} ${escapeShellArgs cfg.extraArgs}
        '';

        # No custom ExecStop: `coli serve` runs in the foreground and systemd's
        # default cgroup-wide kill on stop takes down its spawned engine
        # subprocess with it (same reasoning as ds4-server).
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
    };

    networking.firewall =
      mkIf cfg.openFirewall { allowedTCPPorts = [ cfg.port ]; };
  };
}
