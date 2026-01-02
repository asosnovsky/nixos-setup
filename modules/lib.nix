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
      modules = [
        determinate.nixosModules.default
        stylix.nixosModules.stylix
        home-manager.nixosModules.default
        nix-flatpak.nixosModules.nix-flatpak
        specialArgs.dms.nixosModules.dankMaterialShell
        (import ./main.nix {
          inherit
            user
            homeManagerVersion
            hostName
            systemStateVersion;
        })
      ] ++ configuration;
    };
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
  # makeDarwinModule =
  #   { system ? "x86_64-darwin"
  #   , user
  #   , ...
  #   }@attrs:
  #   nix-darwin.lib.darwinSystem {
  #     modules =
  #       (makeImports {
  #         attrs = attrs;
  #         extraConfiguration = [
  #           home-manager.darwinModules.home-manager
  #           stylix.darwinModules.stylix
  #         ];
  #       })
  #       ++ [
  #         (import ./macos.nix {
  #           user = user;
  #           system = system;
  #         })
  #       ];
  #   };
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
  makeNixOs = makeNixOs;
  makeNixosConfigurations =
    nodes:
    builtins.listToAttrs (
      builtins.map
        ({ hostName
         , ...
         }@attrs: {
          name = hostName;
          value = makeNixOs
            {
              inherit hostName;
            } // attrs;
        })
        nodes
    );
}
