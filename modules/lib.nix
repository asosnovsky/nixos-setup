{ nixpkgs
, home-manager
, nix-darwin
, systems
, hlCommonSettings
, gBar
}:
let
  makeImports =
    { attrs
    , extraConfiguration ? [ ]
    }: (if (isNull attrs.configuration) then [ ] else [ attrs.configuration ])
      ++ [
      (import ./main.nix (attrs // { inherit gBar; }))
    ] ++ extraConfiguration;
  eachSystem = nixpkgs.lib.genAttrs (import systems);
  allPkgs = eachSystem (system:
    import nixpkgs {
      system = system;
      config = { allowUnfree = true; };
    });
  makeNixOsModuleMaker =
    masterAttrs:
    { system ? masterAttrs.system ? "x86_64-linux"
    , configuration ? null
    , ...
    }@attrs:
    let joinedttrs = masterAttrs // attrs;
    in
    nixpkgs.lib.nixosSystem {
      system = system;
      modules = (makeImports {
        attrs = joinedttrs;
        extraConfiguration = [
          home-manager.nixosModules.default
        ];
      });
    };
  makeNixOsModule =
    makeNixOsModuleMaker { };
  makeHLService = makeNixOsModuleMaker hlCommonSettings;
  makeDarwinModule =
    { system ? "x86_64-darwin"
    , user
    , configuration ? null
    , ...
    }@attrs:
    nix-darwin.lib.darwinSystem {
      modules = (makeImports {
        attrs = attrs;
        extraConfiguration = [
          home-manager.darwinModules.home-manager
        ];
      }) ++ [
        (import ./macos.nix {
          user = user;
          system = system;
        })
      ];
    };
  makeHomeManagerUsers =
    { modules ? [ ]
    , homeManagerVersion
    , user
    , system ? "x86_64-linux"
    }:
    let
      hm = (import ./home {
        stateVersion = homeManagerVersion;
      });
      pkgs = allPkgs."${system}";
    in
    home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        (hm.makeCommonUser user)
      ] ++ modules;
    };
in
{
  eachSystem = eachSystem;
  pkgs = allPkgs;
  makeNixOsModule = makeNixOsModule;
  makeHLService = makeHLService;
  makeDarwinModule = makeDarwinModule;
  makeHomeManagerUsers = makeHomeManagerUsers;
  makeHLServices =
    { nodeNames ? [ ]
    , systemStateVersion ? "24.05"
    , user
    }: builtins.listToAttrs (builtins.map
      (name: {
        name = name;
        value = makeHLService {
          hostName = name;
          configuration = (import (../hosts + "/${name}.nix") { user = user; });
          systemStateVersion = systemStateVersion;
        };
      })
      nodeNames);
}
