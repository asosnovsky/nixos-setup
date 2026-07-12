from niri_touchscreen_gestures.detector.base_types import (
    DetectorState,
    FingerNumber,
    Slot,
)


def empty_slot() -> Slot:
    return Slot(
        tracking_id=-1,
        start_x=0,
        start_y=0,
        last_x=0,
        last_y=0,
    )


def initial_state() -> DetectorState:
    return DetectorState(
        slots={FingerNumber(i): empty_slot() for i in range(10)},
        current_slot=FingerNumber(0),
    )
