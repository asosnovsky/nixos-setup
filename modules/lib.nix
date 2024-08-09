{ nixpkgs
, home-manager
, nix-darwin
, lix-module
, systems
, hlCommonSettings
}:
let
  makeImports =
    { attrs
    , home-manager-modules
    , extraConfiguration ? [ ]
    }: (if (isNull attrs.configuration) then [ ] else [ attrs.configuration ])
      ++ [
      (import ./main.nix attrs)
    ] ++ (if attrs.home-manager.enable then
      home-manager-modules
    else
      [ ]) ++ extraConfiguration;
  eachSystem = nixpkgs.lib.genAttrs (import systems);
  pkgs = eachSystem (system:
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
        home-manager-modules = [ home-manager.nixosModules.default ];
        extraConfiguration = [ lix-module.nixosModules.default ];
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
        home-manager-modules = [
          home-manager.darwinModules.home-manager
          (import ./home-manager/macos.nix { user = user; })
        ];
      }) ++ [
        (import ./macos.nix {
          user = user;
          system = system;
        })
      ];
    };
in
{
  eachSystem = eachSystem;
  pkgs = pkgs;
  makeNixOsModule = makeNixOsModule;
  makeHLService = makeHLService;
  makeDarwinModule = makeDarwinModule;
  makeHLServices =
    { nodeNames ? [ ]
    , systemStateVersion ? "24.05"
    , user
    }: builtins.listToAttrs (builtins.map
      (name: {
        name = name;
        value = makeHLService {
          hostName = name;
          configuration = (import (./hosts + "/${name}.nix") { user = user; });
          systemStateVersion = systemStateVersion;
        };
      })
      nodeNames);
}
