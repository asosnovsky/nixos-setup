{ ... }:
{
  imports = [
    ./exporters.nix
    ./admin.nix
    ./acme
    ./arrs
    ./k8s
    ./k3s
    ./services
    ./timers.nix
    ./dns
  ];
}
