{ pkgs, unstablePkgs, myPkgs, ... }:
{
  environment.systemPackages =
    (with pkgs; [
      rustc
      go
      pipx
      uv
      zed-editor-fhs
      nix-prefetch
      herdr
      mangohud
      unstablePkgs.ollama-rocm
      unstablePkgs.grok-build
      unstablePkgs.goose-cli
      lmstudio
      signal-cli
      blueman
      unstablePkgs.devenv

      unstablePkgs.grok-build
      unstablePkgs.pi-coding-agent
      unstablePkgs.goose-cli
      unstablePkgs.claude-agent-acp
      unstablePkgs.claude-code
    ])
    ++ [ myPkgs.ds4-rocm ];
}
