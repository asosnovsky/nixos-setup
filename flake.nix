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
    # <---  Cosmic Desktop Trials
    nixos-cosmic = {
      url = "github:lilyinstarlight/nixos-cosmic";
      inputs.nixpkgs.follows = "unstable";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };
    # Cosmic Desktop Trials ---/>
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
      # <---  Cosmic Desktop Trials
    , nixos-cosmic
      # Cosmic Desktop Trials ---/>
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
      # Libs
      lib = (import modules/lib.nix {
        nixpkgs = nixpkgs;
        home-manager = home-manager;
        nix-darwin = nix-darwin;
        lix-module = lix-module;
      });
      unstableLib = (import modules/lib.nix {
        nixpkgs = unstable;
        home-manager = unstable-home-manager;
        nix-darwin = nix-darwin;
        lix-module = lix-module;
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
      makeunstableHLService = unstableLib.makeNixOsModuleMaker hlCommonSettings;
      homeLabModulesUsingStable = builtins.map
        (name: {
          name = name;
          value = makeHLService {
            hostName = name;
            configuration = (import (./hosts + "/${name}.nix") { user = user; });
            systemStateVersion = "24.05";
          };
        })
        ([
          "hl-minipc1"
          "hl-minipc2"
          "hl-terra1"
        ]);
      homeLabModulesUsingUnStable = builtins.map
        (name: {
          name = name;
          value = makeunstableHLService {
            hostName = name;
            configuration = (import (./hosts + "/${name}.nix") { user = user; });
            systemStateVersion = "24.05";
          };
        })
        ([
          "hl-bigbox1"
        ]);
    in
    {
      lib = lib;
      formatter =
        eachSystem (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);

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


      nixosConfigurations = {
        # NIXOS Framework Setups
        # -------------
        fwbook = lib.makeNixOsModule {
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
            # <---  Cosmic Desktop Trials
            nix.settings = {
              substituters = [ "https://cosmic.cachix.org/" ];
              trusted-public-keys = [ "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE=" ];
            };
            services.desktopManager.cosmic.enable = true;
            services.displayManager.cosmic-greeter.enable = true;
            # Cosmic Desktop Trials ---/>
            imports = [
              # <---  Cosmic Desktop Trials
              nixos-cosmic.nixosModules.default
              # Cosmic Desktop Trials ---/>
              nixos-hardware.nixosModules.framework-13-7040-amd
              (import ./hosts/fwbook.nix {
                user = user;
                unstable = unstablePkgs.x86_64-linux;
              })
            ];
          };
        };
        # NIXOS Framework Homelab
        # -------------
        hl-fws1 = makeHLService {
          hostName = "hl-fws1";
          configuration = { ... }: {
            imports = [
              nixos-hardware.nixosModules.framework-11th-gen-intel
              (import (./hosts/hl-fws1.nix) { user = user; })
            ];
          };
          systemStateVersion = "24.05";
        };
      } // (builtins.listToAttrs homeLabModulesUsingStable) // (builtins.listToAttrs homeLabModulesUsingUnStable);
    };
}
