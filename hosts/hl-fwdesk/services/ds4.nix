{ myPkgs, ... }:
let
  ports = { ds4 = 8000; };
in
{
  services.ds4 = {
    enable = true;
    package = (myPkgs.ds4-rocm.override { rocmArch = "gfx1151"; });
    user = "ari";
    group = "users";
    model = "/var/lib/ds4/ds4flash.gguf";
    host = "0.0.0.0";
    port = ports.ds4;
    ctx = 100000;
    kvDiskDir = "/var/lib/ds4/kv";
    kvDiskSpaceMb = 8192;
    cors = true;
    environment.HSA_ENABLE_SDMA = "0";
    openFirewall = true;
    autoStart = false;
    extraArgs = [ "--kv-cache-reject-different-quant" ];
    extraServiceConfig.TimeoutStopSec = "300";
  };
}
