import logging
import threading
from dataclasses import dataclass
from typing import Callable

import evdev

from niri_touchscreen_gestures.actions import ForwardScroll, GestureAction
from niri_touchscreen_gestures.config import GestureConfig
from niri_touchscreen_gestures.detector.base_types import (
    DetectorState,
    FingerNumber,
    Slot,
)
from niri_touchscreen_gestures.detector.classifiers import (
    classify_direction,
    classify_tap,
    count_active_fingers,
)
from niri_touchscreen_gestures.detector.inits import empty_slot, initial_state

logger = logging.getLogger(__name__)

DOUBLE_TAP_WINDOW_S = 0.35
DOUBLE_TAP_MOVE_THRESHOLD = 40  # px, max distance between the two taps
TAP_MOVE_THRESHOLD = 15  # px, max finger movement to still count as a tap
LONG_PRESS_S = 0.5


@dataclass(frozen=True)
class _SwipeSignal:
    key: str


@dataclass(frozen=True)
class _TapSignal:
    kind: str  # "tap" | "long-tap"
    x: int
    y: int
    time: float


@dataclass(frozen=True)
class _ScrollSignal:
    key: str
    delta: float


_Signal = _SwipeSignal | _TapSignal | _ScrollSignal


@dataclass
class _PendingTap:
    timer: threading.Timer
    x: int
    y: int
    time: float
    app_id: str | None


class GestureDetector:
    """Detects gestures from raw evdev events and dispatches resolved actions.

    Discrete gestures (swipes, long-taps, the second tap of a double-tap) are
    resolved and dispatched as soon as the triggering event arrives. A lone
    short tap can't be resolved immediately -- it might turn out to be the
    first half of a double-tap -- so it's dispatched from a background
    `threading.Timer` if no second tap follows within `DOUBLE_TAP_WINDOW_S`.
    """

    def __init__(
        self,
        config: GestureConfig,
        dispatch: Callable[[GestureAction, float], None],
        get_app_id: Callable[[], str | None],
        threshold: int = 60,
        timer_factory: Callable[..., threading.Timer] = threading.Timer,
    ) -> None:
        self.config = config
        self.dispatch = dispatch
        self.get_app_id = get_app_id
        self.threshold = threshold
        self.timer_factory = timer_factory
        self._state = initial_state()
        self._lock = threading.RLock()
        self._app_id_queried = False
        self._cached_app_id: str | None = None
        self._pending_tap: _PendingTap | None = None
        self._scroll_active = False

    def handle_event(self, ev: evdev.InputEvent) -> None:
        """Mutates internal state and dispatches any resolved action."""
        self._state, signal = _handle_event(self._state, ev, self.threshold)
        if signal is not None:
            self._process_signal(signal)
        if count_active_fingers(self._state.slots) == 0:
            with self._lock:
                self._app_id_queried = False
                self._cached_app_id = None
                self._scroll_active = False

    def _current_app_id(self) -> str | None:
        with self._lock:
            if not self._app_id_queried:
                self._cached_app_id = self.get_app_id()
                self._app_id_queried = True
            return self._cached_app_id

    def _process_signal(self, signal: _Signal) -> None:
        if isinstance(signal, _SwipeSignal):
            if signal.key.startswith("2-finger-") and self._scroll_active:
                return  # already forwarded as continuous scroll -- don't double-dispatch
            self._resolve_and_dispatch(signal.key, self._current_app_id())
        elif isinstance(signal, _ScrollSignal):
            action = self.config.resolve(signal.key, self._current_app_id())
            if isinstance(action, ForwardScroll):
                self._scroll_active = True
                self.dispatch(action, signal.delta)
        elif isinstance(signal, _TapSignal):
            self._process_tap(signal)

    def _process_tap(self, tap: _TapSignal) -> None:
        if tap.kind == "long-tap":
            self._resolve_and_dispatch("1-finger-long-tap", self._current_app_id())
            return

        with self._lock:
            pending = self._pending_tap
            is_second_tap = (
                pending is not None
                and (tap.time - pending.time) <= DOUBLE_TAP_WINDOW_S
                and max(abs(tap.x - pending.x), abs(tap.y - pending.y))
                <= DOUBLE_TAP_MOVE_THRESHOLD
            )
            if is_second_tap:
                assert pending is not None
                pending.timer.cancel()
                self._pending_tap = None
                app_id = pending.app_id
            else:
                if pending is not None:
                    pending.timer.cancel()
                app_id = self._current_app_id()
                timer = self.timer_factory(
                    DOUBLE_TAP_WINDOW_S, self._resolve_pending_tap, args=(app_id,)
                )
                self._pending_tap = _PendingTap(
                    timer=timer, x=tap.x, y=tap.y, time=tap.time, app_id=app_id
                )
                timer.daemon = True
                timer.start()

        if is_second_tap:
            self._resolve_and_dispatch("1-finger-double-tap", app_id)

    def _resolve_pending_tap(self, app_id: str | None) -> None:
        with self._lock:
            self._pending_tap = None
        self._resolve_and_dispatch("1-finger-tap", app_id)

    def _resolve_and_dispatch(self, key: str, app_id: str | None) -> None:
        logger.info(f"Detected {key=} {app_id=}")
        action = self.config.resolve(key, app_id)
        if action is not None:
            self.dispatch(action, 0.0)


def _handle_event(
    state: DetectorState,
    ev: evdev.InputEvent,
    threshold: int,
) -> tuple[DetectorState, _Signal | None]:
    """Pure event handler. Returns (new_state, signal_or_None)."""
    if ev.type != evdev.ecodes.EV_ABS:
        return state, None
    slot: Slot = state.slots.get(state.current_slot, empty_slot()).copy()
    new_slots: dict[FingerNumber, Slot] = {k: v.copy() for k, v in state.slots.items()}

    if ev.code == evdev.ecodes.ABS_MT_SLOT:
        return DetectorState(slots=new_slots, current_slot=FingerNumber(ev.value)), None

    if ev.code == evdev.ecodes.ABS_MT_TRACKING_ID:
        if ev.value == -1:
            signal: _Signal | None = None
            if slot["tracking_id"] != -1:
                dx = slot["last_x"] - slot["start_x"]
                dy = slot["last_y"] - slot["start_y"]
                finger_count = count_active_fingers(state.slots)
                if finger_count == 1:
                    tap_kind = classify_tap(
                        dx,
                        dy,
                        ev.timestamp() - slot["start_time"],
                        TAP_MOVE_THRESHOLD,
                        LONG_PRESS_S,
                    )
                    if tap_kind:
                        signal = _TapSignal(
                            tap_kind, slot["last_x"], slot["last_y"], ev.timestamp()
                        )
                if signal is None:
                    direction = classify_direction(dx, dy, threshold)
                    if direction:
                        signal = _SwipeSignal(f"{finger_count}-finger-{direction}")
            new_slots[state.current_slot] = empty_slot()
            return DetectorState(slots=new_slots, current_slot=state.current_slot), signal
        else:
            slot = Slot(
                tracking_id=ev.value,
                start_x=0,
                start_y=0,
                last_x=0,
                last_y=0,
                start_time=ev.timestamp(),
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
        prev_y = slot["last_y"]
        if slot["start_y"] == 0:
            slot["start_y"] = ev.value
        slot["last_y"] = ev.value
        new_slots[state.current_slot] = slot
        new_state = DetectorState(slots=new_slots, current_slot=state.current_slot)

        # Stream continuous scroll ticks for 2-finger vertical drags, instead of
        # waiting for finger-lift like the discrete swipe classifier does.
        finger_count = count_active_fingers(new_slots)
        if prev_y != 0 and finger_count == 2:
            delta = float(ev.value - prev_y)
            if delta != 0:
                return new_state, _ScrollSignal(f"{finger_count}-finger-scroll", delta)
        return new_state, None

    return state, None
