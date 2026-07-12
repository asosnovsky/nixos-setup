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
    # Secrets management
    agenix.url = "github:ryantm/agenix";
  };

  outputs =
    { self
    , nixpkgs-unstable
    , determinate
    , nixos-hardware
    , nixpkgs
    , systems
    , home-manager
    , nix-darwin
    , nix-flatpak
    , stylix
    , hyprlauncher
    , dms
    , noctalia
    , git-hooks
    , nix-index-database
    , agenix
    , hermes-agent
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
                nixpkgs-unstable
                dms
                noctalia
                nix-index-database
                hermes-agent
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
            };
          };
        in
        {
          default = pkgs.mkShell {
            name = "nixos-setup";
            packages = with pkgs; [
              nixpkgs-fmt
              nixd
              nh
              agenix.packages.${system}.default
              age
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
          grok-cli = lib.pkgs.${system}.grok-cli;
          # CPU variant of DwarfStar (antirez/ds4); buildable on any system.
          # GPU variants (ds4-rocm/ds4-cuda) are overlay-only — see modules/core.
          ds4 = lib.pkgs.${system}.ds4;
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
