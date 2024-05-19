{ nixpkgs
, home-manager
, nix-darwin
}:
let
  makeImports =
    { attrs
    , home-manager-modules
    }: (if (isNull attrs.configuration) then [ ] else [ attrs.configuration ])
      ++ [
      (import ./main.nix attrs)
    ] ++ (if attrs.home-manager.enable then
      home-manager-modules
    else
      [ ]);
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
          (import ./macos-home-manager.nix { user = user; })
        ];
      }) ++ [
        (import ./macos.nix {
          user = user;
          system = system;
        })
      ];
    };
}
