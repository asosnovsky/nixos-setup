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
      homeMangerVersion = "24.05";
    in
    {
      nixosConfigurations."fwbook" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          nixos-hardware.nixosModules.framework-13-7040-amd
          home-manager.nixosModules.default
          (import ./hosts/fwbook.nix {
            user = user;
          })
          (import ./modules/main.nix {
            user = user;
            systemStateVersion = "23.11";
            hostName = "fwbook";
            home-manager = {
              enable = true;
              version = homeMangerVersion;
            };
            desktop = {
              enable = true;
              user = user;
              enableKDE = true;
              enableHypr = true;
              enableX11 = true;
            };
            os = {
              enable = true;
              firewall = {
                enable = false;
              };
              enableFonts = true;
              enableNetowrking = true;
              enableSSH = false;
              hardware = {
                enable = true;
              };
            };
          })
        ];
      };
    };
}
