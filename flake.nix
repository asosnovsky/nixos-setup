{
  inputs = {
    # Hardware
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    systems.url = "github:nix-systems/default";
    # Nixpkgs
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0";
    nixpkgs-unstable.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    # Flatpak
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=main";
    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Themes
    stylix = {
      url = "github:nix-community/stylix/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Macos
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Hyprland
    hyprlauncher.url = "github:hyprwm/hyprlauncher";
  };

  outputs =
    { self
    , nixpkgs-unstable
    , determinate
    , nixos-hardware
    , nixpkgs
    , systems
    , home-manager
    , nix-darwin
    , nix-flatpak
    , stylix
    , hyprlauncher
    }:
    let
      user = {
        name = "ari";
        fullName = "Ari Sosnovsky";
        email = "ariel@sosnovsky.ca";
      };
      homeManagerVersion = "24.11";
      # Local Services
      localNixCaches = {
        urls = [
          "http://minipc1.lab.internal:5000"
        ];
        keys = [
          "minipc1.lab.internal:buUlsyg+xRqkUk0MWACmIyRUtHIOPQQzg7nc4qZCc4E="
        ];
      };
      localDockerRegistries = [ "minipc1.lab.internal:5001" ];
      hlCommonSettings = {
        system = "x86_64-linux";
        user = user;
        localNixCaches = localNixCaches;
        homeManagerVersion = homeManagerVersion;
        os = {
          enable = true;
          firewall = { enable = false; };
          enableFonts = true;
          hardware = { enable = false; };
          enablePrometheusExporters = true;
          containers = {
            runtime = "docker";
            localDockerRegistries = localDockerRegistries;
          };
        };
      };
      # Lib Config
      libConfig = {
        inherit
          determinate
          nix-darwin
          hlCommonSettings
          systems
          nix-flatpak
          stylix
          ;
        specialArgs = {
          inputs =
            {
              inherit
	              hyprlauncher
                nixpkgs-unstable;
            };
        };
      };
      # Libs
      lib = (import modules/lib.nix ({
        nixpkgs = nixpkgs;
        home-manager = home-manager;
      } // libConfig));
      homelabServices = (
        (lib.makeHLServices {
          user = user;
          nodeNames = [
            "hl-minipc1"
            "hl-minipc2"
            "hl-minipc3"
            "hl-terra1"
            "hl-bigbox1"
          ];
        })
      );
    in
    {
      # Dev Setups
      # -------------
      devShells =
        lib.eachSystem (system:
          let pkgs = nixpkgs.legacyPackages.${system};
          in
          {
            default = pkgs.mkShell {
              name = "nixos-setup";
              packages = with pkgs; [
                nixpkgs-fmt
                nixd
                nh
              ];
              shellHook = ''
                export PATH=$PATH:$(pwd)/bin
              '';
            };
          });
      lib = lib;
      formatter =
        lib.eachSystem (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);

      # None-NIXOS LINUX Setups
      # -------------
      homeConfigurations."${user.name}" = lib.makeHomeManagerUsers {
        inherit user homeManagerVersion;
      };

      # NIXOS LINUX Setups
      # -------------
      nixosConfigurations = {
        # NIXOS Framework Setups
        # -------------
        fwbook = lib.makeNixOsModule {
          system = "x86_64-linux";
          user = user;
          systemStateVersion = "23.11";
          hostName = "fwbook";
          # localNixCaches = localNixCaches;
          localDockerRegistries = localDockerRegistries;
          homeManagerVersion = homeManagerVersion;
          os = {
            enable = true;
            firewall = { enable = false; };
            enableFonts = true;
            enableNetworking = true;
            enableSSH = false;
            hardware = { enable = true; };
            containers = {
              localDockerRegistries = localDockerRegistries;
              runtime = "docker";
            };
            enablePrometheusExporters = true;
          };
          configuration = { ... }: {
            imports = [
              nixos-hardware.nixosModules.framework-13-7040-amd
              (import ./hosts/fwbook.nix {
                user = user;
              })
            ];
          };
        };
        # NIXOS Framework Homelab
        # -------------
        hl-fws1 = lib.makeHLService {
          hostName = "hl-fws1";
          configuration = { ... }: {
            imports = [
              nixos-hardware.nixosModules.framework-11th-gen-intel
              (import (./hosts/hl-fws1.nix) { user = user; })
            ];
          };
          systemStateVersion = "24.05";
        };
        # NIXOS Framework Desktop
        # -------------
        hl-fwdesk = lib.makeHLService {
          hostName = "hl-fwdesk";
          configuration = { ... }: {
            imports = [
              nixos-hardware.nixosModules.framework-desktop-amd-ai-max-300-series
              (import (./hosts/hl-fwdesk.nix) { user = user; })
            ];
          };
          systemStateVersion = "25.05";
        };
      } // homelabServices;
    };
}
