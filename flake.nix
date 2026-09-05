{
  inputs = {
    # Hardware
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    systems.url = "github:nix-systems/default";
    # Pre-commit hooks
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Nixpkgs
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0";
    nixpkgs-unstable.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    flox.url = "github:flox/flox/latest";
    # nix-index database (for nix-index and comma)
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # DankShell
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    # Noctalia
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Hermes
    hermes-agent.url = "github:NousResearch/hermes-agent";
    # Flatpak
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=main";
    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Themes
    stylix = {
      url = "github:nix-community/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Macos
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Hyprland
    hyprlauncher.url = "github:hyprwm/hyprlauncher";
    # Hyprland compositor via flake (latest git).
    hyprland.url = "github:hyprwm/Hyprland";

    # Secrets management
    agenix.url = "github:ryantm/agenix";
    # Claude Desktop
    claude-desktop = {
      url = "github:patrickjaja/claude-desktop-extra";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Tether — iPhone ↔ Linux Wayland bridge
    tether = {
      url = "github:zackb/tether";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    { self
    , nixpkgs-unstable
    , flox
    , determinate
    , nixos-hardware
    , nixpkgs
    , systems
    , home-manager
    , nix-darwin
    , nix-flatpak
    , stylix
    , hyprlauncher
    , hyprland
    , dms
    , noctalia
    , git-hooks
    , nix-index-database
    , agenix
    , hermes-agent
    , claude-desktop
    , tether
    }:
    let
      # Libs
      lib =
        import modules/lib.nix
          {
            user = {
              name = "ari";
              fullName = "Ari Sosnovsky";
              email = "ariel@sosnovsky.ca";
            };
            rootDir = ./.;
            inherit
              nixpkgs
              nixpkgs-unstable
              home-manager
              determinate
              nix-darwin
              systems
              nix-flatpak
              stylix
              agenix
              ;

            specialArgs = {
              inherit
                hyprlauncher
                hyprland
                nixpkgs-unstable
                dms
                noctalia
                nix-index-database
                hermes-agent
                claude-desktop
                flox
                determinate
                tether
                ;
            };
          }
      ;
    in
    {
      # Dev Setups
      # -------------
      devShells = lib.eachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          pre-commit-check = git-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixpkgs-fmt.enable = true;
              stylua.enable = true;
            };
          };
        in
        {
          default = pkgs.mkShell {
            name = "nixos-setup";
            packages = with pkgs; [
              nixpkgs-fmt
              stylua
              nixd
              nh
              agenix.packages.${system}.default
              age
              # yq-go — YAML linting used by `skyg encrypt --yaml`
              yq
              home-manager.packages.${system}.home-manager
              rustc
              cargo
              rust-analyzer
              nushell
              # Python tooling for niri-touchscreen-gestures script
              python3
              python3Packages.evdev
              python3Packages.tomli
              python3Packages.pydantic
              python3Packages.pydantic-settings
              python3Packages.pytest
              libinput
              wlrctl
              ydotool
            ];
            shellHook = ''
                            export PATH=$PATH:$(pwd)/bin
                            export SKYG_LIB="$(pwd)/bin/lib/cmds.nu"
                            ${pre-commit-check.shellHook}

                            if [ -z "$NU_VERSION" ] && [ -t 0 ] && command -v nu >/dev/null; then
                              cat <<'BANNER'
                 ____  _          ____   ____  _          _ _
                / ___|| | ___   _/ ___| / ___|| |__   ___| | |
                \___ \| |/ / | | | |  _  \___ \| '_ \ / _ \ | |
                 ___) |   <| |_| | |_| |  ___) | | | |  __/ | |
                |____/|_|\_\\__, |\____| |____/|_| |_|\___|_|_|
                            |___/
              BANNER
                              exec nu --execute "use \"$SKYG_LIB\" *"
                            fi
            '';
          };
        }
      );
      lib = lib;
      formatter = lib.eachSystem (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);
      packages = lib.eachSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          openwrt = import ./modules/openwrt { inherit pkgs; inherit (nixpkgs) lib; };
        in
        {
          openwrt-glmain = (openwrt (import ./openwrt-routers/glmain.nix)).deployScript;
          openwrt-glmain-dry-run = (openwrt (import ./openwrt-routers/glmain.nix)).dryRunScript;
          grok-cli = lib.pkgs.${system}.grok-cli;
          # CPU variant of DwarfStar (antirez/ds4); buildable on any system.
          # GPU variants (ds4-rocm/ds4-cuda) are overlay-only — see modules/core.
          ds4 = lib.pkgs.${system}.ds4;
          claude-desktop = pkgs.callPackage ./pkgs/claude-desktop { };
          # Buzz Desktop AppImage (block/buzz) with NixOS FHS extras.
          buzz-desktop = lib.pkgs.${system}.buzz-desktop;
          # CPU variant of colibrì (JustVugg/colibri); the ROCm variant
          # (colibri-rocm) is overlay-only — see modules/core.
          colibri = lib.pkgs.${system}.colibri;
        }
      );

      # Non-NixOS Linux Setups (standalone home-manager)
      # -------------
      homeConfigurations = {
        "ari" = lib.makeHomeManagerUsers { };
      };

      # NixOS Linux Setups
      # -------------
      nixosConfigurations =
        {
          fwbook = lib.makeNixOs {
            hostName = "fwbook";
            systemStateVersion = "23.11";
            configuration = [
              ./hosts/fwbook.nix
              ./hosts/fwbook.hardware-configuration.nix
              nixos-hardware.nixosModules.framework-13-7040-amd
            ];
          };
          hl-fws1 = lib.makeNixOs {
            hostName = "hl-fws1";
            configuration = [
              ./hosts/hl-fws1.nix
              ./hosts/hl-fws1.hardware-configuration.nix
              nixos-hardware.nixosModules.framework-11th-gen-intel
            ];
          };
          hl-fwdesk = lib.makeNixOs {
            hostName = "hl-fwdesk";
            systemStateVersion = "25.05";
            configuration = [
              ./hosts/hl-fwdesk.nix
              ./hosts/hl-fwdesk.hardware-configuration.nix
              nixos-hardware.nixosModules.framework-desktop-amd-ai-max-300-series
            ];
          };
          hl-bigbox1 = lib.makeNixOs {
            hostName = "hl-bigbox1";
            configuration = [
              ./hosts/hl-bigbox1.nix
              ./hosts/hl-bigbox1.hardware-configuration.nix
            ];
          };
          hl-bigbox2 = lib.makeNixOs {
            hostName = "hl-bigbox2";
            systemStateVersion = "25.05";
            configuration = [
              ./hosts/hl-bigbox2.nix
              ./hosts/hl-bigbox2.hardware-configuration.nix
            ];
          };
          hl-minipc1 = lib.makeNixOs {
            hostName = "hl-minipc1";
            configuration = [
              ./hosts/hl-minipc1.nix
              ./hosts/hl-minipc1.hardware-configuration.nix
            ];
          };
          hl-minipc2 = lib.makeNixOs {
            hostName = "hl-minipc2";
            configuration = [
              ./hosts/hl-minipc2.nix
              ./hosts/hl-minipc2.hardware-configuration.nix
            ];
          };
          hl-minipc3 = lib.makeNixOs {
            hostName = "hl-minipc3";
            configuration = [
              ./hosts/hl-minipc3.nix
              ./hosts/hl-minipc3.hardware-configuration.nix
            ];
          };
          hl-pi1 = lib.makeSdImage {
            system = "aarch64-linux";
            hostName = "hl-pi1";
            configuration = [
              ./hosts/hl-pi1.nix
              ./hosts/hl-pi1.hardware-configuration.nix
            ];
          };
          hl-pi2 = lib.makeSdImage {
            system = "aarch64-linux";
            hostName = "hl-pi2";
            configuration = [
              ./hosts/hl-pi2.nix
              ./hosts/hl-pi2.hardware-configuration.nix
            ];
          };
          hl-terra1 = lib.makeNixOs {
            hostName = "hl-terra1";
            configuration = [
              ./hosts/hl-terra1.nix
              ./hosts/hl-terra1.hardware-configuration.nix
            ];
          };
          iso = lib.makeIso {
            hostName = "skygnix";
            configuration = [
              ./hosts/iso.nix
            ];
          };
        };
    };
}
