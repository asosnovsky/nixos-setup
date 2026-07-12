from collections.abc import Iterable

import evdev


def identify_touchscreen_via_evdev() -> Iterable[evdev.InputDevice]:
    for path in evdev.list_devices():
        dev = evdev.InputDevice(path)
        name_lower = dev.name.lower()
        if "touchscreen" in name_lower or "touch panel" in name_lower:
            yield dev
        if caps := dev.capabilities(absinfo=False).get(evdev.ecodes.EV_ABS):
            if evdev.ecodes.ABS_X in caps and evdev.ecodes.ABS_Y in caps:
                if ("mouse" not in name_lower) and ("touchpad" not in name_lower):
                    yield dev
