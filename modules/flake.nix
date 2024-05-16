{
  description = "Main Flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, home-manager, nix-darwin, nixpkgs }: {
    lib = {
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
    };
  };
}
