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
    ])
    ++ [ myPkgs.ds4-rocm ];
}
