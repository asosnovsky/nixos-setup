from typing import Literal

from niri_touchscreen_gestures.detector.base_types import (
    FingerNumber,
    Slot,
    SwipeDirection,
)

TapKind = Literal["tap", "long-tap"]


def count_active_fingers(slots: dict[FingerNumber, Slot]) -> int:
    return sum(1 for s in slots.values() if s["tracking_id"] != -1)


def classify_direction(dx: int, dy: int, threshold: int) -> SwipeDirection | None:
    """Pure direction classifier."""
    ax, ay = abs(dx), abs(dy)
    if max(ax, ay) < threshold:
        return None
    if ax > ay:
        return "right" if dx > 0 else "left"
    return "down" if dy > 0 else "up"


def classify_tap(
    dx: int, dy: int, duration: float, move_threshold: int, long_press_s: float
) -> TapKind | None:
    """Pure tap classifier. Returns None if the finger moved past
    `move_threshold` (i.e. it was a swipe, not a tap)."""
    if max(abs(dx), abs(dy)) >= move_threshold:
        return None
    return "long-tap" if duration >= long_press_s else "tap"
