{
  imports = [
    ./tailscale.nix
    ./nix-serve.nix
    ./docker-registry.nix
    ./gitea.nix
    ./gitea-container.nix
    ./public-gitea.nix
    ./acme.nix
    ./portainer.nix
    ./iu.nix
    ./audiobookshelf.nix
    ./buzz.nix
  ];
}
