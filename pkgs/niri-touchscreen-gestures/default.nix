{ lib
, python3
, wlrctl
, ...
}:

python3.pkgs.buildPythonApplication {
  pname = "niri-touchscreen-gestures";
  version = "0.1.0";

  src = ./.;

  pyproject = true;

  build-system = with python3.pkgs; [
    hatchling
  ];

  dependencies = with python3.pkgs; [
    evdev
    pydantic
    pydantic-settings
    typing-extensions
  ];

  # Gestures forwarded to the focused app (clicks/scroll) shell out to wlrctl,
  # which uses niri's native wlr-virtual-pointer/virtual-keyboard protocol
  # support -- no uinput/root daemon needed.
  makeWrapperArgs = [
    "--prefix"
    "PATH"
    ":"
    (lib.makeBinPath [ wlrctl ])
  ];

  meta = {
    description = "Touchscreen gesture detector for niri (2/3/4-finger swipes → niri actions, plus click/scroll forwarding to the focused app). Just run `niri-touchscreen-gestures` — no config needed.";
    homepage = "https://github.com/skykanin/nixos-setup";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
    platforms = lib.platforms.linux;
    mainProgram = "niri-touchscreen-gestures";
  };
}
