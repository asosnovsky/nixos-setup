from collections.abc import Iterable

import evdev
from evdev import ecodes


def identify_touchscreen_via_evdev() -> Iterable[evdev.InputDevice]:
    """Yield the real touchscreens, selected by capability rather than by name.

    INPUT_PROP_DIRECT is the kernel's own statement that the device's coordinates
    map directly onto the display, which is what distinguishes a touchscreen from
    the two kinds of device that otherwise look identical:

      * a touchpad, which is absolute but reports INPUT_PROP_POINTER instead
      * a synthetic pointer such as `dotool absolute pointer`, which reports
        ABS_X/ABS_Y and no props at all

    Matching on ABS_X/ABS_Y and an absent "touchpad"/"mouse" substring used to
    accept both, so the daemon detected its own click-forwarding device as a
    second touchscreen and refused to start.

    Multitouch axes are required as well: a device without them cannot report the
    finger counts every gesture in the detector is defined in terms of.
    """
    for path in evdev.list_devices():
        dev = evdev.InputDevice(path)
        if ecodes.INPUT_PROP_DIRECT not in dev.input_props():
            continue
        abs_axes = dev.capabilities(absinfo=False).get(ecodes.EV_ABS, [])
        if ecodes.ABS_MT_POSITION_X in abs_axes and ecodes.ABS_MT_POSITION_Y in abs_axes:
            yield dev
