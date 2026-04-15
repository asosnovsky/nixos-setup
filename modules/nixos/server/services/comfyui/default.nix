{ ... }:
{
  imports = [
    ./shared.nix
    ./rocm.nix
    ./rocm-docker.nix
    ./cuda.nix
  ];
}
