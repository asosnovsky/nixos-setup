{ ... }:
{
  imports = [
    ./audiobookshelf.nix
    ./ai-services.nix
    ./bazel-build.nix
    ./colibri.nix
    ./comfyui
    ./jellyfin.nix
    ./nbot-agent.nix
    ./signal-cli.nix
  ];
}
