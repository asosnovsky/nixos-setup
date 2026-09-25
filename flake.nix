{
  inputs = {
    # my apps
    skygqts.url = "git+ssh://gitea@minipc1.lab.internal:22/ari/skygqts.git";
    skygqts.inputs.nixpkgs.follows = "nixpkgs";
    hermenix.url = "git+ssh://gitea@minipc1.lab.internal:22/ari/hermenix.git";
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
    determinate.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0";
    nixpkgs-unstable.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    # my fork of nixpkgs
    my-nixpkgs.url = "github:asosnovsky/nixpkgs/ds4-init";
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
    # DankShell greeter (moved out of the dms repo)
    dank-greeter = {
      url = "github:AvengeMedia/dank-greeter";
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

    # Tether — iPhone ↔ Linux Wayland bridge
    tether = {
      url = "github:zackb/tether";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    herdr.url = "github:herdrdev/herdr";
    # Declarative disk partitioning (for nixos-anywhere installs)
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    { self
    , skygqts
    , hermenix
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
    , my-nixpkgs
    , dms
    , dank-greeter
    , noctalia
    , git-hooks
    , nix-index-database
    , agenix
    , hermes-agent
    , tether
    , herdr
    , disko
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
            configsDir = ./configs;
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
              skyg-secrets = {
                buzz-env = ./secrets/buzz-env.age;
                cloudflare-dns = ./secrets/cloudflare-dns.age;
                portainer-agent-minipc1 = ./secrets/portainer-agent-minipc1.age;
                portainer-agent-bigbox1 = ./secrets/portainer-agent-bigbox1.age;
                portainer-tls-key = ./secrets/portainer-tls-key.age;
                stack1 = ./secrets/stack1.age;
                stack2 = ./secrets/stack2.age;
                portainer-agent-minipc3 = ./secrets/portainer-agent-minipc3.age;
                portainer-cert = ./configs/pki/portainer.app.internal.crt;
              };
              inherit
                hyprlauncher
                hyprland
                nixpkgs-unstable
                my-nixpkgs
                dms
                dank-greeter
                noctalia
                nix-index-database
                hermes-agent
                skygqts
                hermenix
                flox
                determinate
                tether
                herdr
                ;
            };
          }
      ;
      dnsAggregate = import ./modules/dns-aggregate.nix { inherit (nixpkgs) lib; };
    in
    {
      # Dev Setups
      # -------------
      devShells = lib.eachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          qtDocs = pkgs.qt6.qtdoc;
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
            QMLLS_DOC_DIR = "${qtDocs}/share/doc/qt6";
            QML_IMPORT_PATH = "${pkgs.qt6.qtdeclarative}/lib/qt-6/qml:${pkgs.quickshell}/lib/qt-6/qml";
            QT_PLUGIN_PATH = "${pkgs.qt6.qtdeclarative}/lib/qt-6/plugins";
            packages = with pkgs; [
              qtDocs
              qt6.qtdeclarative
              nixpkgs-fmt
              stylua
              nixd
              nh
              agenix.packages.${system}.default
              age
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
                            export CLAUDE_CONFIG_DIR="$(pwd)/.claude-nixos-setup"
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

      # Flat view of every internal DNS record declared by any host:
      #   nix eval .#dnsRecords --json | jq
      dnsRecords = dnsAggregate.records self.nixosConfigurations;

      formatter = lib.eachSystem (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);
      packages = lib.eachSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          openwrt = import ./modules/openwrt { inherit pkgs; inherit (nixpkgs) lib; };
          # Internal DNS records declared across all hosts (skyg.dns), rendered
          # as the generalMappings fragment merged into the router config.
          dnsRecordsFile = pkgs.writeText "skyg-dns-records.json"
            (builtins.toJSON (dnsAggregate.json self.nixosConfigurations));
          glmain = (import ./openwrt-routers/glmain.nix) // { dnsRecords = dnsRecordsFile; };
        in
        {
          openwrt-glmain = (openwrt glmain).deployScript;
          openwrt-glmain-dry-run = (openwrt glmain).dryRunScript;
          skyg-dns-records = dnsRecordsFile;
          ds4 = my-nixpkgs.legacyPackages.${system}.ds4;
          buzz-desktop = lib.pkgs.${system}.buzz-desktop;
          superset-desktop = lib.pkgs.${system}.superset-desktop;
          delta-editor = lib.pkgs.${system}.delta-editor;
          colibri = lib.pkgs.${system}.colibri;
          herdr = herdr.packages.${system}.default;
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
              ./hosts/fwbook
              nixos-hardware.nixosModules.framework-13-7040-amd
            ];
          };
          hl-fws1 = lib.makeNixOs {
            hostName = "hl-fws1";
            configuration = [
              ./hosts/hl-fws1
              ./hosts/hl-fws1.disko.nix
              nixos-hardware.nixosModules.framework-11th-gen-intel
              disko.nixosModules.disko
            ];
          };
          hl-fwdesk = lib.makeNixOs {
            hostName = "hl-fwdesk";
            systemStateVersion = "25.05";
            configuration = [
              ./hosts/hl-fwdesk
              nixos-hardware.nixosModules.framework-desktop-amd-ai-max-300-series
              hermenix.nixosModules.default
            ];
          };
          hl-bigbox1 = lib.makeNixOs {
            hostName = "hl-bigbox1";
            configuration = [
              ./hosts/hl-bigbox1
            ];
          };
          hl-bigbox2 = lib.makeNixOs {
            hostName = "hl-bigbox2";
            systemStateVersion = "25.05";
            configuration = [
              ./hosts/hl-bigbox2
            ];
          };
          hl-minipc1 = lib.makeNixOs {
            hostName = "hl-minipc1";
            configuration = [
              ./hosts/hl-minipc1
            ];
          };
          hl-minipc2 = lib.makeNixOs {
            hostName = "hl-minipc2";
            configuration = [
              ./hosts/hl-minipc2
            ];
          };
          hl-minipc3 = lib.makeNixOs {
            hostName = "hl-minipc3";
            configuration = [
              ./hosts/hl-minipc3
            ];
          };
          hl-pi1 = lib.makeSdImage {
            system = "aarch64-linux";
            hostName = "hl-pi1";
            configuration = [
              ./hosts/hl-pi1
            ];
          };
          hl-pi2 = lib.makeSdImage {
            system = "aarch64-linux";
            hostName = "hl-pi2";
            configuration = [
              ./hosts/hl-pi2
            ];
          };
          hl-terra1 = lib.makeNixOs {
            hostName = "hl-terra1";
            configuration = [
              ./hosts/hl-terra1
            ];
          };
          iso = lib.makeIso {
            hostName = "skygnix";
            configuration = [
              ./hosts/iso
            ];
          };
        };
    };
}
