from niri_touchscreen_gestures.detector.base_types import (
    FingerNumber,
    Slot,
    SwipeDirection,
)


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
