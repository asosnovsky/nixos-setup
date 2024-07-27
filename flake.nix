{
  inputs = {
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    unstable.url = "github:NixOS/nixpkgs/master";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    systems.url = "github:nix-systems/default";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    unstable-home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "unstable";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixos-hardware
    , nixpkgs
    , home-manager
    , nix-darwin
    , systems
    , unstable
    , unstable-home-manager
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
      localNixCaches = [
        "http://minipc1.lab.internal:5000"
        "http://fwlaptop.devices.internal:5000"
      ];
      localDockerRegistries = [ "minipc1.lab.internal:5001" ];
      # Libs
      lib = (import modules/lib.nix {
        nixpkgs = nixpkgs;
        home-manager = home-manager;
        nix-darwin = nix-darwin;
      });
      unstableLib = (import modules/lib.nix {
        nixpkgs = unstable;
        home-manager = unstable-home-manager;
        nix-darwin = nix-darwin;
      });
      eachSystem = nixpkgs.lib.genAttrs (import systems);
      unstablePkgs = eachSystem (system:
        import unstable {
          system = system;
          config = { allowUnfree = true; };
        });
      hlCommonSettings = {
        system = "x86_64-linux";
        user = user;
        localNixCaches = localNixCaches;
        enableNetworkDrives = true;
        enableHomelabServices = true;
        home-manager = {
          enable = true;
          version = homeManagerVersion;
          enableDevelopmentKit = false;
        };
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
      makeHLService = lib.makeNixOsModuleMaker hlCommonSettings;
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
        localNixCaches = localNixCaches;
        localDockerRegistries = localDockerRegistries;
        home-manager = {
          enable = true;
          version = homeManagerVersion;
          enableDevelopmentKit = true;
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
              unstable = unstablePkgs.x86_64-linux;
            })
          ];
        };
      };

      # MacBooks Setups
      # -------------
      darwinConfigurations."asosnovsky-mac" = lib.makeDarwinModule {
        user = sumoUser;
        systemStateVersion = 4;
        localNixCaches = localNixCaches;
        system = "x86_64-darwin";
        hostName = "asosnovsky-mac";
        home-manager = {
          enable = true;
          enableDevelopmentKit = true;
          version = homeManagerVersion;
        };
        configuration =
          (import ./hosts/asosnovsky-mac.nix { user = sumoUser; });
      };

      # NIXOS Homelab - BIGBOX1
      # -------------
      nixosConfigurations."hl-bigbox1" = unstableLib.makeNixOsModule (hlCommonSettings // {
        systemStateVersion = "24.05";
        hostName = "hl-bigbox1";
        home-manager = {
          enable = true;
          enableDevelopmentKit = false;
          version = "24.11";
        };
        configuration = (import ./hosts/hl-bigbox1.nix { user = user; });
      });

      # NIXOS Homelab - minipc1
      # -------------
      nixosConfigurations."hl-minipc1" = makeHLService {
        hostName = "hl-minipc1";
        configuration = (import ./hosts/hl-minipc1.nix { user = user; });
        systemStateVersion = "23.11";
      };

      # NIXOS Homelab - minipc2
      # -------------
      nixosConfigurations."hl-minipc2" = makeHLService {
        hostName = "hl-minipc2";
        configuration = (import ./hosts/hl-minipc2.nix { user = user; });
        systemStateVersion = "24.05";
      };
    };
}
