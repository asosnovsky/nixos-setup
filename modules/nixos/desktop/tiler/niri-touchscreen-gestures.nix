{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.skyg.nixos.desktop.tiler.niri.touchscreen-gestures;
  skygUser = config.skyg.user;

  gestureArgs =
    lib.optionals (cfg.touchOutput != null) [ "--touch-output" cfg.touchOutput ]
    ++ lib.optionals (cfg.device != null) [ "--device" cfg.device ]
    ++ lib.optionals (cfg.configFile != null) [ "--config" cfg.configFile ]
    ++ [ "--threshold" (toString cfg.threshold) ];
in
{
  options = {
    skyg.nixos.desktop.tiler.niri.touchscreen-gestures = {
      enable = lib.mkEnableOption "touchscreen gesture support for niri";

      touchOutput = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "eDP-1";
        description = ''
          Name of the niri output the touchscreen is mapped to, used to place
          forwarded taps at the position actually touched. Should match the
          `touch { map-to-output }` target in the niri config.

          Required whenever more than one output is enabled — the daemon cannot
          guess which one the panel corresponds to and will refuse to start.
        '';
      };

      device = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "/dev/input/event5";
        description = ''
          Explicit evdev device path. Leave null to auto-detect, which fails if
          the machine exposes more than one touchscreen.
        '';
      };

      threshold = lib.mkOption {
        type = lib.types.ints.positive;
        default = 60;
        description = "Minimum pixels of movement before a swipe registers.";
      };

      configFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "%h/.config/niri/gestures.toml";
        description = ''
          Path to a TOML gesture config. Leave null to use the built-in defaults
          (3-finger swipes for workspace/column navigation, 4-finger for
          overview). systemd specifiers such as `%h` are expanded.

          The file must exist if set — the daemon treats a missing config as a
          fatal error rather than falling back to defaults.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.skyg.nixos.desktop.tiler.niri.enable;
        message = ''
          skyg.nixos.desktop.tiler.niri.touchscreen-gestures.enable requires
          skyg.nixos.desktop.tiler.niri.enable — the daemon drives niri over its
          IPC socket and has no meaning under another compositor.
        '';
      }
    ];

    environment.systemPackages = [
      pkgs.niri-touchscreen-gestures
      # dotool provides the absolute pointer positioning used to forward taps.
      # ydotool is deliberately not used here: its `mousemove --absolute` is
      # really a warp-to-corner plus a *relative* delta, so the compositor's
      # pointer acceleration scales it (measured at exactly 2x on this layout,
      # saturating at the screen edge). dotool registers a uinput device with a
      # declared absolute axis range instead, which no acceleration curve can
      # distort.
      pkgs.dotool
    ];

    # dotool writes to /dev/uinput, which this makes group-accessible (0660,
    # group "uinput") and loads the kernel module for. Note that dotool ships no
    # udev rules of its own in nixpkgs, so this is the only thing granting access.
    hardware.uinput.enable = true;

    # "input" is already granted by tiler.enable (needed to read /dev/input for
    # the touchscreen); "uinput" is what hardware.uinput.enable creates.
    users.users.${skygUser.name}.extraGroups = [ "input" "uinput" ];

    systemd.user.services = {
      # Registering a uinput device costs a noticeable startup delay, so keep one
      # long-running daemon rather than paying it on every tap.
      dotoold = {
        description = "dotoold - uinput backend for absolute pointer positioning";
        after = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = lib.getExe' pkgs.dotool "dotoold";
          Restart = "on-failure";
          RestartSec = 2;
        };
      };

      niri-touchscreen-gestures = {
        description = "Touchscreen gesture bridge for niri";
        # Needs the niri IPC socket, which only exists once the compositor is up,
        # and dotoold's virtual device before it can forward a tap.
        after = [ "graphical-session.target" "dotoold.service" ];
        wants = [ "dotoold.service" ];
        partOf = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = "${lib.getExe pkgs.niri-touchscreen-gestures} ${lib.escapeShellArgs gestureArgs}";
          Restart = "on-failure";
          RestartSec = 2;
        };
      };
    };
  };
}
