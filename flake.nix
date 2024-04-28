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
          nixos-hardware.nixosModules.framework-13-7040-amd
          home-manager.nixosModules.default
          fh.packages.x86_64-linux.default
          (import ./hosts/fwbook.nix {
            user = user;
          })
          (import ./modules/os/main.nix {
            user = user;
            hostName = hostName;
            firewall = {
              enable = true;
            };
            enableCore = true;
            enableFonts = true;
            enableNetowrking = true;
            enableSSH = false;
            hardware = {
              enable = true;
              enableFingerPrint = true;
            };
            systemStateVersion = systemStateVersion;
          })
          (import ./modules/rootUser.nix {
            hostName = hostName;
          })
          (import ./modules/user.nix {
            user = user;
          })
          (import ./modules/optional/hyprland.nix {
            user = user;
          })
          ./modules/optional/gnome.nix
          (import ./modules/optional/home-manager-config.nix {
            user = user;
            hostName = hostName;
            homeMangerVersion = homeMangerVersion;
          })
          {
            # enable docker
            virtualisation.docker.enable = true;
          }
        ];
      };
    };
}
