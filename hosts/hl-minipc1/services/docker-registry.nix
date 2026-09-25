{ ... }:
let
  ports = { dockerRegistry = 5001; };
in
{
  services.dockerRegistry = {
    enable = true;
    storagePath = "/mnt/Data/docker-registry";
    port = ports.dockerRegistry;
    openFirewall = true;
    listenAddress = "0.0.0.0";
    enableDelete = true;
  };
}
