{ nixpkgs
, home-manager
, nix-darwin
, lix-module
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
in
{
  makeNixOsModule =
    { system
    , configuration ? null
    , ...
    }@attrs:
    nixpkgs.lib.nixosSystem {
      system = system;
      modules = (makeImports {
        attrs = attrs;
        home-manager-modules = [ home-manager.nixosModules.default ];
        extraConfiguration = [ lix-module.nixosModules.default ];
      });
    };
  makeNixOsModuleMaker =
    masterAttrs:
    { system ? masterAttrs.system ? "x86_64-linux"
    , configuration ? null
    , ...
    }@attrs:
    nixpkgs.lib.nixosSystem {
      system = system;
      modules = (makeImports {
        attrs = masterAttrs // attrs;
        home-manager-modules = [ home-manager.nixosModules.default ];
      });
    };
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
}
