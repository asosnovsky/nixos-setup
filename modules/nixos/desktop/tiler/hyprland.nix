{ config
, lib
, pkgs
, skygUtils
, hyprland
, hyprgrass
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
      hyprgrass.packages.${system}.hyprgrass
    ];

    # Resolved store path for the hyprgrass plugin .so, read by
    # configs/fwbook/hypr/conf/hyprgrass.lua via os.getenv to call
    # hl.plugin.load(...). Adding the package to systemPackages above only
    # puts the file on disk -- Hyprland needs an explicit load call, and the
    # store path changes on every flake update so it can't be hardcoded there.
    environment.sessionVariables.HYPRGRASS_SO =
      "${hyprgrass.packages.${system}.hyprgrass}/lib/libhyprgrass.so";

    # Symlink ~/.config/hypr -> configs/<configName>/hypr (host-specific).
    system.userActivationScripts.hyprlandConfig.text = skygUtils.makeHyperlinkScriptToConfigs {
      filePath = "${cfg.configName}/hypr";
      targetPath = "hypr";
      configSource = "/home/${config.skyg.user.name}/nixos-setup/configs";
    };
  };
}
