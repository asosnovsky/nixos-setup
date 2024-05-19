{ nixpkgs
, home-manager
, nix-darwin
}:
{
  makeNixOsModule = { system, configuration ? null, ... }@attrs:
    nixpkgs.lib.nixosSystem {
      system = system;
      modules = (if (isNull configuration) then [ ] else [ configuration ]) ++
        (if attrs.home-manager.enable then
          [ home-manager.nixosModules.default ]
        else
          [ ]);
    };
  makeDarwinModule =
    { system ? "x86_64-darwin", user, configuration ? null, ... }@attrs:
    nix-darwin.lib.darwinSystem {
      modules = (import ./main.nix attrs)
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
    };
}
