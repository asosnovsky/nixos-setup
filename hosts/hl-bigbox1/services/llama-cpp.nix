{ ... }:

{
  # llama.cpp with DFlash2 speculative decoding on RTX 3060 (12GB VRAM).
  #
  # Off by default: it needs ~19 GB of weights on disk. Fetch the files, then
  # flip enable:
  #
  #   sudo install -d -o ari -g users /var/lib/llama-cpp
  #   cd /var/lib/llama-cpp
  #   curl -L -O https://huggingface.co/ggml-org/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-Q4_K_M.gguf
  #   curl -L -O https://huggingface.co/z-lab/Qwen3.8-27B-DFlash2-GGUF/resolve/main/Qwen3.8-27B-DFlash2-Q8_0.gguf
  #
  # Measured expectation: ~15-25 tok/s (RTX 3060 has less bandwidth than Strix
  # Halo, but the dedicated VRAM is snappier for inference).
  skyg.nixos.server.services.llama-cpp = {
    enable = false;

    package = "llama-cpp-cuda";
    model = "/var/lib/llama-cpp/Qwen3.8-27B-Q4_K_M.gguf";
    draftModel = "/var/lib/llama-cpp/Qwen3.8-27B-DFlash2-Q8_0.gguf";
    specType = "draft-dflash";
    specDraftNMax = 7;

    ctx = 32768;
    kvCacheType = "q8_0";
    cacheReuse = 256;

    # RTX 3060: 12GB VRAM, offload most layers but leave headroom for context.
    gpuLayers = 30;
    parallel = 2;

    host = "0.0.0.0";
    port = 8081;
    openFirewall = true;
  };
}
