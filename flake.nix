{
  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-23.11;
  inputs.home-manager.url = github:nix-community/home-manager;
  inputs.fh.url = "https://flakehub.com/f/DeterminateSystems/fh/*.tar.gz";
  inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";


  outputs =
    { self
    , nixpkgs
    , home-manager
    , fh
    , nixos-hardware
    }@attrs:
    let
      user = {
        name = "ari";
        fullName = "Ari Sosnovsky";
        email = "ariel@sosnovsky.ca";
      };
      dataDir = "/mnt/Data";
      systemStateVersion = "23.11";
      homeMangerVersion = "23.11";
      hostName = "fwbook";
    in
    {
      nixosConfigurations.fwbook = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hardware-configs/fwbook.nix
          nixos-hardware.nixosModules.framework-13-7040-amd
          (import ./modules/os/nix.nix {
            systemStateVersion = systemStateVersion;
          })
          (import ./modules/os/core.nix {
            user = user;
            hostName = hostName;
            firewall = { enable = true; };
          })
        ];
      };
    };
}
