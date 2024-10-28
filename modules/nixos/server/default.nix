{ ... }:
{
  imports = [
    ./audiobookshelf.nix
    ./coral-tpu-udev.nix
    ./exporters.nix
    ./ai-services.nix
    ./jellyfin.nix
    ./admin.nix
    ./arrs
    ./k8s
  ];
}
