{
  inputs = {
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixos-hardware, nixpkgs, home-manager, nix-darwin, systems }:
    let
      user = {
        name = "ari";
        fullName = "Ari Sosnovsky";
        email = "ariel@sosnovsky.ca";
      };
      sumoUser = rec {
        name = "asosnovsky";
        fullName = user.fullName;
        email = "${name}@sumologic.com";
        homepath = "/Users/${name}";
        extraGitConfigs = [{ path = "${homepath}/.config/mysumo/gitconfig"; }];
      };
      homeMangerVersion = "24.05";
      lib = (import modules/lib.nix {
        nixpkgs = nixpkgs;
        home-manager = home-manager;
        nix-darwin = nix-darwin;
      });
      eachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      lib = lib;
      formatter =
        eachSystem (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);

      # NIXOS Framework Setups
      # -------------
      nixosConfigurations."fwbook" = lib.makeNixOsModule {
        system = "x86_64-linux";
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
          enableHypr = false;
          enableX11 = true;
          enableWine = true;
        };
        os = {
          enable = true;
          firewall = { enable = false; };
          enableFonts = true;
          enableNetowrking = true;
          enableSSH = false;
          hardware = { enable = true; };
        };
        configuration = { ... }: {
          imports = [
            nixos-hardware.nixosModules.framework-13-7040-amd
            (import ./hosts/fwbook.nix { user = user; })
          ];
        };
      };

      # MacBooks Setups
      # -------------
      darwinConfigurations."asosnovsky-mac" = lib.makeDarwinModule {
        user = sumoUser;
        systemStateVersion = 4;
        system = "x86_64-darwin";
        hostName = "asosnovsky-mac";
        home-manager = {
          enable = true;
          version = homeMangerVersion;
        };
        configuration =
          (import ./hosts/asosnovsky-mac.nix { user = sumoUser; });
      };

      # NIXOS Homelab - BIGBOX1
      # -------------
      nixosConfigurations."hl-bigbox1" = lib.makeNixOsModule {
        system = "x86_64-linux";
        user = user;
        systemStateVersion = "24.05";
        hostName = "hl-bigbox1";
        home-manager = {
          enable = true;
          version = homeMangerVersion;
        };
        os = {
          enable = true;
          firewall = { enable = false; };
          enableFonts = true;
          enableNetowrking = true;
          enableSSH = true;
          hardware = { enable = true; };
        };
        configuration = (import ./hosts/hl-bigbox1.nix { user = user; });
      };
    };
}
