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
    ];

    # Symlink ~/.config/hypr -> configs/<configName>/hypr (host-specific).
    system.userActivationScripts.hyprlandConfig = lib.mkIf cfg.configLink.enable {
      text = skygUtils.makeHyperlinkScriptToConfigs {
        filePath = "${cfg.configName}/hypr";
        targetPath = "hypr";
        configSource = "/home/${config.skyg.user.name}/nixos-setup/configs";
      };
    };
  };
}
