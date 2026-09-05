{ config
, lib
, pkgs
, skygUtils
, hyprland
, noctalia
, ...
}:
let
  cfg = config.skyg.nixos.desktop.tiler.hyprland;
  system = pkgs.stdenv.hostPlatform.system;
  hyprlandPkg = hyprland.packages.${system}.hyprland;
  hyprlandPortal = hyprland.packages.${system}.xdg-desktop-portal-hyprland;
  noctaliaPkg = noctalia.packages.${system}.default;

  # When mountAsSource is set, build a real, GC-protected copy of the hypr config
  # dir. The flake self-source path (skyg.rootDir) is not referenced by the system
  # closure, so it gets garbage-collected and the ~/.config/hypr symlink dangles.
  # This derivation is added to the system profile, pinning it against GC.
  bakedHyprConfig = pkgs.stdenv.mkDerivation {
    pname = "${cfg.configName}-hypr-config";
    version = "1";
    src = "${config.skyg.rootDir}/configs/${cfg.configName}/hypr";
    buildPhase = "true";
    installPhase = ''
      mkdir -p "$out/${cfg.configName}"
      cp -r "$src" "$out/${cfg.configName}/hypr"
    '';
  };
in
{
  options = {
    skyg.nixos.desktop.tiler.hyprland = {
      enable = lib.mkEnableOption "hyprland";
      configName = lib.mkOption {
        type = lib.types.str;
        default = config.skyg.core.hostName;
        description = ''
          Name of the per-host Hyprland config directory under `configs/`.
          The module symlinks `~/.config/hypr` -> `configs/<configName>/hypr`.
          Defaults to the machine's hostName (e.g. `fwbook` -> `configs/fwbook/hypr`).
        '';
      };
      configLink = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Whether to symlink `~/.config/hypr` -> `configs/<configName>/hypr`.
            Disable on hosts that manage their own Hyprland config elsewhere.
          '';
        };
        mountAsSource = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            If `configLink.enable` is true, embed the config dir in the build.
            A GC-protected copy of the config is baked into the system closure
            (via a derivation added to the system profile) instead of symlinking
            to the live `~/nixos-setup/configs` checkout, making the config part
            of the built system and reproducible.
          '';
        };
      };
    };
  };
  config = lib.mkIf cfg.enable {
    skyg.nixos.desktop.tiler.enable = true;

    programs.hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
      package = hyprlandPkg;
      portalPackage = hyprlandPortal;
    };
    programs.uwsm.enable = true;

    xdg.portal = {
      enable = true;
      extraPortals = [ hyprlandPortal ];
    };

    # Shell + tools that the Hyprland session/config expect.
    environment.systemPackages = with pkgs; [
      noctaliaPkg
      hypridle
      wofi
      rofi
      wl-clipboard
      grim
      slurp
      satty
    ] ++ (lib.optionals cfg.configLink.mountAsSource [ bakedHyprConfig ]);

    # Symlink ~/.config/hypr -> configs/<configName>/hypr (host-specific).
    system.userActivationScripts.hyprlandConfig = lib.mkIf cfg.configLink.enable {
      text = skygUtils.makeHyperlinkScriptToConfigs {
        filePath = "${cfg.configName}/hypr";
        targetPath = "hypr";
        configSource =
          if cfg.configLink.mountAsSource then
            "${bakedHyprConfig}"
          else
            "/home/${config.skyg.user.name}/nixos-setup/configs";
      };
    };
  };
}
