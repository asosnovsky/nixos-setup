import logging

import evdev

from niri_touchscreen_gestures.config import GestureConfig
from niri_touchscreen_gestures.detector.base_types import (
    DetectorState,
    FingerNumber,
    Slot,
)
from niri_touchscreen_gestures.detector.classifiers import (
    classify_direction,
    count_active_fingers,
)
from niri_touchscreen_gestures.detector.inits import empty_slot, initial_state
from niri_touchscreen_gestures.nirictl import SupportedActions

logger = logging.getLogger(__name__)


class GestureDetector:
    def __init__(self, config: GestureConfig, threshold: int = 60) -> None:
        self.config = config
        self.threshold = threshold
        self._state = initial_state()

    def handle_event(self, ev: evdev.InputEvent) -> SupportedActions | None:
        """Return action or None. Mutates internal state."""
        self._state, action = _handle_event(
            self._state, ev, self.config, self.threshold
        )
        return action


def _handle_event(
    state: DetectorState,
    ev: evdev.InputEvent,
    config: GestureConfig,
    threshold: int,
) -> tuple[DetectorState, SupportedActions | None]:
    """Pure event handler. Returns (new_state, action_or_None)."""
    if ev.type != evdev.ecodes.EV_ABS:
        return state, None

    slot: Slot = state.slots.get(state.current_slot, empty_slot()).copy()
    new_slots: dict[FingerNumber, Slot] = {k: v.copy() for k, v in state.slots.items()}

    if ev.code == evdev.ecodes.ABS_MT_SLOT:
        return DetectorState(slots=new_slots, current_slot=FingerNumber(ev.value)), None

    if ev.code == evdev.ecodes.ABS_MT_TRACKING_ID:
        if ev.value == -1:
            if slot["tracking_id"] != -1:
                dx = slot["last_x"] - slot["start_x"]
                dy = slot["last_y"] - slot["start_y"]
                direction = classify_direction(dx, dy, threshold)
                if direction:
                    finger_count = count_active_fingers(state.slots)
                    key = f"{finger_count}-finger-{direction}"
                    logger.info(f"Detected {key=}")
                    action = config.get(key)
                    if action:
                        new_slots[state.current_slot] = empty_slot()
                        return (
                            DetectorState(
                                slots=new_slots, current_slot=state.current_slot
                            ),
                            action,
                        )
            slot = empty_slot()
        else:
            slot = Slot(
                tracking_id=ev.value,
                start_x=0,
                start_y=0,
                last_x=0,
                last_y=0,
            )
        new_slots[state.current_slot] = slot
        return DetectorState(slots=new_slots, current_slot=state.current_slot), None

    if ev.code == evdev.ecodes.ABS_MT_POSITION_X:
        if slot["start_x"] == 0:
            slot["start_x"] = ev.value
        slot["last_x"] = ev.value
        new_slots[state.current_slot] = slot
        return DetectorState(slots=new_slots, current_slot=state.current_slot), None

    if ev.code == evdev.ecodes.ABS_MT_POSITION_Y:
        if slot["start_y"] == 0:
            slot["start_y"] = ev.value
        slot["last_y"] = ev.value
        new_slots[state.current_slot] = slot
        return DetectorState(slots=new_slots, current_slot=state.current_slot), None

    return state, None
