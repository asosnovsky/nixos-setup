{ ... }:

{
  # llama.cpp with DFlash2 speculative decoding.
  #
  # Off by default: it needs ~19 GB of weights on disk and a first build of the
  # ROCm package. Fetch the files, then flip enable:
  #
  #   sudo install -d -o ari -g users /var/lib/llama-cpp
  #   cd /var/lib/llama-cpp
  #   curl -L -O https://huggingface.co/ggml-org/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-Q4_K_M.gguf
  #   curl -L -O https://huggingface.co/z-lab/Qwen3.8-27B-DFlash2-GGUF/resolve/main/Qwen3.8-27B-DFlash2-Q8_0.gguf
  #
  # Measured expectation for this box: ~25-40 tok/s, not the 380 tok/s in the
  # post that prompted this — that figure is a 3090 copying a document.
  skyg.nixos.server.services.llama-cpp = {
    enable = false;

    model = "/var/lib/llama-cpp/Qwen3.8-27B-Q4_K_M.gguf";
    draftModel = "/var/lib/llama-cpp/Qwen3.8-27B-DFlash2-Q8_0.gguf";
    specType = "draft-dflash";
    specDraftNMax = 7;

    ctx = 32768;
    kvCacheType = "q8_0";
    cacheReuse = 256;

    host = "0.0.0.0";
    port = 8081;
    openFirewall = true;
  };
}
