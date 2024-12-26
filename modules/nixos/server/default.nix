{ ... }:
{
  imports = [
    ./exporters.nix
    ./admin.nix
    ./arrs
    ./k8s
    ./services
    ./timers.nix
  ];
}
