{
  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-23.11;
  inputs.home-manager.url = github:nix-community/home-manager;
  # inputs.fh.url = "https://flakehub.com/f/DeterminateSystems/fh/*.tar.gz";
  inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";


  outputs =
    { self
    , nixpkgs
    , home-manager
      # , fh
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
          (import ./hosts/fwbook.nix {
            user = user;
          })
          (import ./main.nix {
            enableFingerPrint = true;
            hostName = "fwbook";
            user = user;
          })
          ./modules/optional/amd-packages.nix
          ./modules/optional/gnome.nix
          (import ./modules/optional/hyprland.nix {
            user = user;
          })
        ];
      };
    };
}
