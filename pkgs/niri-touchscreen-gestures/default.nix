{ lib
, python3
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
  ],
  ];

  meta = {
    description = "Touchscreen gesture detector for niri (2/3/4-finger swipes → niri actions)";
    homepage = "https://github.com/skykanin/nixos-setup";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
    platforms = lib.platforms.linux;
    mainProgram = "niri-touchscreen-gestures";
  };
}
