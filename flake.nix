{
  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
  inputs.home-manager.url = github:nix-community/home-manager;
  inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";

  outputs =
    { self
    , nixpkgs
    , home-manager
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
      homeMangerVersion = "24.05";
      hostName = "fwbook";
    in
    {
      nixosConfigurations."${hostName}" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          nixos-hardware.nixosModules.framework-13-7040-amd
          home-manager.nixosModules.default
          (import ./hosts/fwbook.nix {
            user = user;
          })
          (import ./modules/nix/main.nix {
            user = user;
            systemStateVersion = systemStateVersion;
          })
          (import ./modules/os/main.nix {
            user = user;
            hostName = hostName;
            firewall = {
              enable = false;
            };
            enableFonts = true;
            enableNetowrking = true;
            enableSSH = false;
            hardware = {
              enable = true;
            };
          })
          (import ./modules/rootUser.nix {
            hostName = hostName;
          })
          (import ./modules/user.nix {
            user = user;
          })
          (import ./modules/desktop/main.nix {
            user = user;
            enableKDE = true;
            enableHypr = true;
            enableX11 = true;
          })
          ./modules/optional/ollama.nix
          (import ./modules/optional/home-manager-config.nix {
            user = user;
            hostName = hostName;
            homeMangerVersion = homeMangerVersion;
          })
        ];
      };
    };
}
