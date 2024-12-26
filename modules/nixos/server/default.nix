{ ... }:
{
  imports = [
    ./coral-tpu-udev.nix
    ./exporters.nix
    ./admin.nix
    ./arrs
    ./k8s
    ./services
    ./timers.nix
  ];
}
