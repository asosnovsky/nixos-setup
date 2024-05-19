{ nixpkgs
, home-manager
, nix-darwin
}:
{
  makeImports = { ... }@attrs: [ (import ./main.nix attrs) ];
  makeNixOsModule = { system, configuration ? null, ... }@attrs:
    nixpkgs.lib.nixosSystem {
      system = system;
      modules = (self.lib.makeImports attrs)
        ++ (if attrs.home-manager.enable then
        [ home-manager.nixosModules.default ]
      else
        [ ])
        ++ (if (isNull configuration) then [ configuration ] else [ ]);
    };
  makeDarwinModule =
    { system ? "x86_64-darwin", user, configuration ? null, ... }@attrs:
    nix-darwin.lib.darwinSystem {
      modules = (self.lib.makeImports attrs)
        ++ (if attrs.home-manager.enable then [
        home-manager.darwinModules.home-manager
        (import ./macos-home-manager.nix { user = user; })
      ] else
        [ ])
        ++ (if (isNull configuration) then [ configuration ] else [ ]) ++ [
        (import ./macos.nix {
          user = user;
          system = system;
        })
      ];
      darwinPackages = self.darwinConfigurations."default".pkgs;
    };
}
