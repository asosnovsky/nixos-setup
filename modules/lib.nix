{ nixpkgs
, nixpkgs-unstable
, user
, determinate
, home-manager
, nix-darwin
, systems
, nix-flatpak
, stylix
, specialArgs
}:
let
  skygUtils = import ./skyg-utils.nix;
  eachSystem = nixpkgs.lib.genAttrs (import systems);
  allPkgs = eachSystem (
    system:
    import nixpkgs {
      system = system;
      config = {
        allowUnfree = true;
      };
    }
  );
  osModules = [
	  determinate.nixosModules.default
	  stylix.nixosModules.stylix
	  home-manager.nixosModules.default
	  nix-flatpak.nixosModules.nix-flatpak
	  specialArgs.dms.nixosModules.dank-material-shell
  ];
  # makeHomeManagerUsers =
  #   { modules ? [ ]
  #   , homeManagerVersion
  #   , user
  #   , system ? "x86_64-linux"
  #   ,
  #   }:
  #   let
  #     hm = (
  #       import ./home {
  #         stateVersion = homeManagerVersion;
  #       }makeHLServices
  #     );
  #     pkgs = allPkgs."${system}";
  #   in
  #   home-manager.lib.homeManagerConfiguration {
  #     inherit pkgs;
  #     modules = [
  #       (hm.makeCommonUser user)
  #     ]
  #     ++ modules;
  #   };
in
{
  eachSystem = eachSystem;
  pkgs = allPkgs;
  makeNixOs =
    { system ? "x86_64-linux"
    , hostName
    , homeManagerVersion ? "24.11"
    , systemStateVersion ? "24.05"
    , configuration ? [ ]
    }: nixpkgs.lib.nixosSystem {
      specialArgs = specialArgs // {
        inherit system skygUtils user;
        unstablePkgs = nixpkgs-unstable.legacyPackages.${system};
      };
      inherit system;
      modules = osModules ++ [
        (import ./main.nix {
          inherit
            user
            homeManagerVersion
            hostName
            systemStateVersion;
        })
      ] ++ configuration;
    };
  makeIso =
    { system ? "x86_64-linux"
    , hostName
    , systemStateVersion ? "25.11"
    , homeManagerVersion ? "25.11"
    , configuration ? [ ]
    }: nixpkgs.lib.nixosSystem {
      specialArgs = specialArgs // {
        inherit system skygUtils user;
        unstablePkgs = nixpkgs-unstable.legacyPackages.${system};
      };
      inherit system;
      modules = osModules ++ [
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        (import ./main.nix {
          inherit
            user
            hostName
            systemStateVersion
            homeManagerVersion
          ;
        })
      ] ++ configuration;
    };
  makeDarwinModule =
    { system ? "x86_64-darwin"
    , user
    , homeManagerVersion ? "25.11"
    , systemStateVersion ? "25.11"
    , hostName
    , configuration ? [ ]
    }:
    nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = specialArgs // {
        inherit system skygUtils user;
        unstablePkgs = nixpkgs-unstable.legacyPackages.${system};
      };
      modules = [
        determinate.darwinModules.default
        home-manager.darwinModules.home-manager
        stylix.darwinModules.stylix
        (import ./macos.nix {
          user = user;
          system = system;
        })
        (import ./main.nix {
          inherit
            user
            homeManagerVersion
            hostName
            systemStateVersion;
        })
      ] ++ configuration;
    };
}
