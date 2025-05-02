{ config, lib, pkgs, ... }:
let
  cfg = config.skyg.nixos.desktop.cosmic;
in
{
  options = {
    skyg.nixos.desktop.cosmic = {
      enable = lib.mkEnableOption
        "Cosmic";
    };
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.cosmic-icons
    ];
    services.desktopManager.cosmic.enable = true;
    hardware.system76.enableAll = true;
    hardware.system76.power-daemon.enable = true;
    home-manager.users.${config.skyg.user.name}.xdg.configFile = {
      "cosmic/com.system76.CosmicSettings.Shortcuts/v1/system_actions" = {
        enable = true;
        force = true;
        text = ''{
          Terminal: "ghostty",
        }'';
      };
      "cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom" = {
        enable = true;
        force = true;
        text = ''
                    {
              (
                  modifiers: [
                      Super,
                      Ctrl,
                  ],
                  key: "Up",
              ): MoveToOutput(Up),
              (
                  modifiers: [
                      Super,
                      Alt,
                      Shift,
                  ],
                  key: "Up",
              ): Disable,
              (
                  modifiers: [
                      Super,
                  ],
                  key: "b",
              ): Spawn("chromium --profile-directory=\'Profile 1\'"),
              (
                  modifiers: [
                      Super,
                      Alt,
                  ],
                  key: "b",
              ): Spawn("chromium --profile-directory=\'Default\'"),
              (
                  modifiers: [
                      Super,
                      Alt,
                      Shift,
                  ],
                  key: "Down",
              ): Disable,
              (
                  modifiers: [
                      Super,
                      Alt,
                      Shift,
                  ],
                  key: "l",
              ): Disable,
              (
                  modifiers: [
                      Super,
                      Alt,
                      Shift,
                  ],
                  key: "Right",
              ): Disable,
              (
                  modifiers: [
                      Super,
                  ],
                  key: "t",
              ): Spawn("ghostty"),
              (
                  modifiers: [
                      Super,
                  ],
                  key: "s",
              ): System(Screenshot),
              (
                  modifiers: [
                      Super,
                      Ctrl,
                  ],
                  key: "Right",
              ): MoveToOutput(Right),
              (
                  modifiers: [
                      Super,
                      Alt,
                      Shift,
                  ],
                  key: "Left",
              ): Disable,
              (
                  modifiers: [
                      Super,
                      Ctrl,
                  ],
                  key: "Left",
              ): MoveToOutput(Left),
              (
                  modifiers: [
                      Super,
                  ],
              ): System(Launcher),
              (
                  modifiers: [
                      Super,
                  ],
                  key: "p",
              ): Spawn("wofi-emoji"),
              (
                  modifiers: [
                      Super,
                      Ctrl,
                  ],
                  key: "Down",
              ): MoveToOutput(Down),
              (
                  modifiers: [
                      Super,
                      Alt,
                      Shift,
                  ],
                  key: "h",
              ): Disable,
              (
                  modifiers: [
                      Super,
                      Alt,
                  ],
                  key: "Left",
              ): MoveToPreviousWorkspace,
              (
                  modifiers: [
                      Super,
                      Alt,
                      Shift,
                  ],
                  key: "k",
              ): Disable,
              (
                  modifiers: [
                      Super,
                      Alt,
                  ],
                  key: "Right",
              ): MoveToNextWorkspace,
              (
                  modifiers: [
                      Super,
                  ],
                  key: "n",
              ): Minimize,
          }
        '';
      };
    };
  };
}
