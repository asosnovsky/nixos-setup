{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.skyg.nixos.server.services.llama-cpp;
  skygUser = config.skyg.user;

  # Target model plus optional drafter. The drafter is only useful for a
  # strategy that matches its architecture: DFlash2 sidecars want
  # `--spec-type draft-dflash`.
  modelFiles = [ cfg.model ] ++ optional (cfg.draftModel != null) cfg.draftModel;

  serverArgs =
    [
      "--model"
      cfg.model
      "--host"
      cfg.host
      "--port"
      (toString cfg.port)
      "--ctx-size"
      (toString cfg.ctx)
      "--n-gpu-layers"
      (toString cfg.gpuLayers)
      "--parallel"
      (toString cfg.parallel)
      "--flash-attn"
      cfg.flashAttention
      "--cache-type-k"
      cfg.kvCacheType
      "--cache-type-v"
      cfg.kvCacheType
      # Qwen-style tool calls arrive as Jinja templates.
      "--jinja"
    ]
    ++ optionals (cfg.draftModel != null) [
      "--model-draft"
      cfg.draftModel
    ]
    ++ optionals (cfg.specType != null) [
      "--spec-type"
      cfg.specType
    ]
    ++ optionals (cfg.specDraftNMax != null) [
      "--spec-draft-n-max"
      (toString cfg.specDraftNMax)
    ]
    # Reuse the longest matching prefix of the previous prompt instead of
    # reprocessing it. This is the "prefix caching" half of the speedup, and it
    # works with any model.
    ++ optionals (cfg.cacheReuse != null) [
      "--cache-reuse"
      (toString cfg.cacheReuse)
    ]
    ++ cfg.extraArgs;

  checkModels = pkgs.writeShellScript "llama-cpp-check-models" ''
    set -eu
    ${concatMapStringsSep "\n" (
      f: ''
        if [ ! -f ${escapeShellArg f} ]; then
          echo "llama-cpp: missing model file: ${f}" >&2
          exit 1
        fi
      ''
    ) modelFiles}
  '';
in
{
  options.skyg.nixos.server.services.llama-cpp = {
    enable = mkEnableOption "the llama.cpp HTTP API (llama-server)";

    package = mkOption {
      type = types.package;
      default = pkgs.llama-cpp-halo;
      defaultText = literalExpression "pkgs.llama-cpp-halo";
      description = ''
        Server package. `pkgs.llama-cpp-halo` is the ROCm build for gfx1151;
        `pkgs.llama-cpp-halo-cpu` is the same tree without the GPU backend.
      '';
    };

    model = mkOption {
      type = types.str;
      example = "/var/lib/llama-cpp/Qwen3.8-27B-Q4_K_M.gguf";
      description = "Path to the target model (GGUF).";
    };

    draftModel = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/var/lib/llama-cpp/Qwen3.8-27B-DFlash2-Q8_0.gguf";
      description = ''
        Optional draft model (GGUF). A drafter must be trained for the exact
        target model — a mismatch loads and then drafts nothing useful.
      '';
    };

    specType = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "draft-dflash";
      description = ''
        Speculative decoding strategy passed to `--spec-type`. Use
        `draft-dflash` for a DFlash/DFlash2 drafter, `draft-mtp` for a model's
        own MTP heads, or `ngram-simple` for prompt-copying workloads (code
        edits, document rewriting) where no drafter is needed at all.
      '';
    };

    specDraftNMax = mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 7;
      description = ''
        Tokens drafted per verification step. Clamped by the drafter's trained
        block size; 7 is the value upstream uses for DFlash2.
      '';
    };

    cacheReuse = mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 256;
      description = ''
        `--cache-reuse`: minimum run of tokens to reuse from a matching prompt
        prefix. 256 is a reasonable default for coding agents.
      '';
    };

    ctx = mkOption {
      type = types.int;
      default = 32768;
      description = "Context size in tokens.";
    };

    kvCacheType = mkOption {
      type = types.enum [
        "f16"
        "bf16"
        "q8_0"
        "q4_0"
      ];
      default = "q8_0";
      description = "KV cache type for both K and V (q8_0 halves KV memory).";
    };

    flashAttention = mkOption {
      type = types.enum [
        "on"
        "off"
        "auto"
      ];
      default = "auto";
      description = "`--flash-attn` value.";
    };

    gpuLayers = mkOption {
      type = types.int;
      default = 99;
      description = ''
        Layers offloaded to the GPU. On Strix Halo the GPU shares system RAM,
        so all layers fit and 99 is the right value.
      '';
    };

    parallel = mkOption {
      type = types.int;
      default = 1;
      description = "Parallel request slots.";
    };

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      example = "0.0.0.0";
      description = "Address llama-server binds to.";
    };

    port = mkOption {
      type = types.port;
      default = 8081;
      description = "TCP port for the HTTP API.";
    };

    user = mkOption {
      type = types.str;
      default = skygUser.name;
      description = "User to run the server as. Needs the render/video groups for GPU access.";
    };

    group = mkOption {
      type = types.str;
      default = "users";
      description = "Group to run the server as.";
    };

    environment = mkOption {
      type = types.attrsOf types.str;
      default = {
        # Same workaround the box's Ollama and ds4 units use.
        HSA_ENABLE_SDMA = "0";
      };
      description = "Environment variables for the service.";
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "--metrics"
        "--no-mmap"
      ];
      description = "Extra arguments appended to the llama-server command line.";
    };

    openFirewall = mkEnableOption "the llama-server port in the firewall";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.specType == null || cfg.draftModel != null || cfg.specType != "draft-dflash";
        message = "services.llama-cpp: specType = \"draft-dflash\" needs a draftModel.";
      }
    ];

    systemd.services.llama-cpp = {
      description = "llama.cpp server (local LLM inference)";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      environment = cfg.environment;
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        ExecStartPre = checkModels;
        ExecStart = "${lib.getExe' cfg.package "llama-server"} ${escapeShellArgs serverArgs}";
        Restart = "on-failure";
        RestartSec = 5;
        # Model files live here; the unit may create it, weights are downloaded
        # by hand (they are tens of GB and not part of the system closure).
        StateDirectory = "llama-cpp";
        WorkingDirectory = "/var/lib/llama-cpp";
        LimitNOFILE = 65536;
        TimeoutStopSec = 120;
      };
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];
  };
}
