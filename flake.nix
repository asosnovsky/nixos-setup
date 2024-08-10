{
  inputs = {
    # Hardware
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    systems.url = "github:nix-systems/default";
    # Nixpkgs
    unstable.url = "github:NixOS/nixpkgs/master";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    # Lix
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.90.0.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    unstable-home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "unstable";
    };
    # Macos
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixos-hardware
    , nixpkgs
    , systems
    , unstable
    , lix-module
    , home-manager
    , unstable-home-manager
    , nix-darwin
    }:
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
      homeManagerVersion = "24.05";
      # Local Services
      localNixCaches = {
        urls = [
          "http://minipc1.lab.internal:5000"
        ];
        keys = [
          "minipc1.lab.internal:eIoib1JgcBEd0YKdW95QlRA2eCKDs+WxNhWhkA1wffc="
        ];
      };
      localDockerRegistries = [ "minipc1.lab.internal:5001" ];
      hlCommonSettings = {
        system = "x86_64-linux";
        user = user;
        localNixCaches = localNixCaches;
        enableNetworkDrives = true;
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
        nix-darwin = nix-darwin;
        lix-module = lix-module;
        hlCommonSettings = hlCommonSettings;
        systems = systems;
      };
      # Libs
      lib = (import modules/lib.nix ({
        nixpkgs = nixpkgs;
        home-manager = home-manager;
      } // libConfig));
      unstableLib = (import modules/lib.nix ({
        nixpkgs = unstable;
        home-manager = unstable-home-manager;
      } // libConfig));
      homelabServices = (
        (lib.makeHLServices {
          user = user;
          nodeNames = [
            "hl-minipc1"
            "hl-minipc2"
            "hl-terra1"
          ];
        }) // (unstableLib.makeHLServices {
          user = user;
          nodeNames = [
            "hl-bigbox1"
          ];
        })
      );
    in
    {
      lib = lib;
      formatter =
        lib.eachSystem (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);

      # MacBooks Setups
      # -------------
      darwinConfigurations."asosnovsky-mac" = lib.makeDarwinModule {
        user = sumoUser // {
          enableDevelopmentKit = true;
        };
        systemStateVersion = 4;
        localNixCaches = localNixCaches;
        system = "x86_64-darwin";
        hostName = "asosnovsky-mac";
        homeManagerVersion = homeManagerVersion;
        configuration =
          (import ./hosts/asosnovsky-mac.nix { user = sumoUser; });
      };

      homeConfigurations."${user.name}" = lib.makeHomeManagerUsers {
        user = user;
        homeManagerVersion = homeManagerVersion;
      };

      nixosConfigurations = {
        # NIXOS Framework Setups
        # -------------
        fwbook = lib.makeNixOsModule {
          system = "x86_64-linux";
          user = user // {
            enableDevelopmentKit = true;
          };
          systemStateVersion = "23.11";
          hostName = "fwbook";
          localNixCaches = localNixCaches;
          localDockerRegistries = localDockerRegistries;
          homeManagerVersion = homeManagerVersion;
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
                unstable = unstableLib.pkgs.x86_64-linux;
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
      } // homelabServices;
    };
}
