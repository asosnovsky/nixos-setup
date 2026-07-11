"""Gesture detection logic using evdev multitouch events."""

from __future__ import annotations

import json
import logging
import subprocess
from typing import Any, Optional

import evdev
from evdev import ecodes as e

from .config import GestureConfig

logger = logging.getLogger(__name__)


class GestureDetector:
    """Detect multi-finger swipes from a touchscreen evdev device."""

    def __init__(
        self, config: GestureConfig | dict[str, Any], threshold: int = 60
    ) -> None:
        if isinstance(config, GestureConfig):
            self.config = config.gestures
        else:
            self.config = config
        self.threshold = threshold
        self.slots: dict[int, dict[str, Any]] = {}
        self.current_slot = 0
        for i in range(10):
            self.slots[i] = {
                "tracking_id": -1,
                "start_x": 0,
                "start_y": 0,
                "last_x": 0,
                "last_y": 0,
            }

    def _classify(self, dx: int, dy: int) -> Optional[str]:
        ax, ay = abs(dx), abs(dy)
        if max(ax, ay) < self.threshold:
            return None
        if ax > ay:
            return "right" if dx > 0 else "left"
        return "down" if dy > 0 else "up"

    def handle_event(self, ev: evdev.InputEvent) -> Optional[list[list[str]]]:
        """Return a list of command arrays to execute, or None."""
        if ev.type == e.EV_ABS:
            slot = self.slots.get(self.current_slot)
            if slot is None:
                return None

            if ev.code == e.ABS_MT_SLOT:
                self.current_slot = ev.value
            elif ev.code == e.ABS_MT_TRACKING_ID:
                if ev.value == -1:
                    # Finger release — check for gesture
                    if slot["tracking_id"] != -1:
                        dx = slot["last_x"] - slot["start_x"]
                        dy = slot["last_y"] - slot["start_y"]
                        direction = self._classify(dx, dy)
                        if direction:
                            # Count how many fingers were active (this one is releasing, plus any still tracked)
                            finger_count = 1 + sum(
                                1 for s in self.slots.values() if s["tracking_id"] != -1
                            )
                            key = f"{finger_count}-finger-{direction}"
                            logger.info(f"Detected {key=}")
                            cmds = self.config.get(key)
                            if cmds:
                                slot.update(
                                    {
                                        "tracking_id": -1,
                                        "start_x": 0,
                                        "start_y": 0,
                                        "last_x": 0,
                                        "last_y": 0,
                                    }
                                )
                                return cmds
                    slot["tracking_id"] = -1
                else:
                    slot["tracking_id"] = ev.value
                    slot["start_x"] = slot["last_x"] = 0
                    slot["start_y"] = slot["last_y"] = 0
            elif ev.code == e.ABS_MT_POSITION_X:
                if slot["start_x"] == 0:
                    slot["start_x"] = ev.value
                slot["last_x"] = ev.value
            elif ev.code == e.ABS_MT_POSITION_Y:
                if slot["start_y"] == 0:
                    slot["start_y"] = ev.value
                slot["last_y"] = ev.value

        return None


def find_touchscreen() -> Optional[str]:
    """Return the first evdev device node that looks like a touchscreen.

    Checks for multitouch slot/tracking id in evdev capabilities, and falls back
    to udev property ID_INPUT_TOUCHSCREEN=1 for devices that report touch via
    ABS_MT_TRACKING_ID without an explicit SLOT axis (common on some Framework
    laptop touchscreens).
    """
    # First pass: strict evdev MT check
    for path in evdev.list_devices():
        try:
            dev = evdev.InputDevice(path)
            caps = dev.capabilities()
            abs_caps = caps.get(e.EV_ABS, [])
            codes = [c[0] if isinstance(c, tuple) else c for c in abs_caps]
            if e.ABS_MT_SLOT in codes or e.ABS_MT_TRACKING_ID in codes:
                return path
        except Exception:
            continue

    # Second pass: udev property fallback via udevadm (no extra Python deps)
    try:
        out = subprocess.run(
            ["udevadm", "info", "--export-db", "--json=short"],
            capture_output=True,
            text=True,
            check=False,
        )
        if out.returncode == 0:
            for rec in json.loads(out.stdout or "[]"):
                if rec.get("ID_INPUT_TOUCHSCREEN") == "1":
                    node = rec.get("DEVNAME") or rec.get("DEVPATH")
                    if node and node.startswith("/dev/input/event"):
                        return node
    except Exception:
        pass
    return None
