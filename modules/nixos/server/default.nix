{ ... }:
{
  imports = [
    ./exporters.nix
    ./admin.nix
    ./arrs
    ./k8s
    ./k3s
    ./services
    ./timers.nix
  ];
}
