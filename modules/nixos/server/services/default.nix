{ ... }:
{
  imports = [
    ./audiobookshelf.nix
    ./ai-services.nix
    ./bazel-build.nix
    ./colibri.nix
    ./comfyui
    ./jellyfin.nix
    ./signal-cli.nix
  ];
}
