{ unstablePkgs, ... }:
let
  ports = { ollama = 11434; };
in
{
  services.open-webui.enable = true;

  users.users.ollama = {
    enable = true;
    home = "/var/lib/ollama";
    extraGroups = [ "render" "video" ];
  };
  services.ollama = {
    enable = true;
    host = "0.0.0.0";
    port = ports.ollama;
    package = unstablePkgs.ollama-rocm;
    user = "ollama";
    home = "/var/lib/ollama";
    environmentVariables = {
      HSA_ENABLE_SDMA = "0";
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_KV_CACHE_TYPE = "q8_0";
      OLLAMA_KEEP_ALIVE = "24h";
    };
  };
}
