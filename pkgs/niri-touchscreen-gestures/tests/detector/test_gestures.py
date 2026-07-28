from niri_touchscreen_gestures.actions import ForwardClick
from niri_touchscreen_gestures.config import GestureConfig
from niri_touchscreen_gestures.coords import map_to_logical
from niri_touchscreen_gestures.detector.classifiers import classify_tap, count_active_fingers
from niri_touchscreen_gestures.detector.gestures import (
    _PendingTap,
    _TapSignal,
    GestureDetector,
)


class TestMapToLogical:
    def test_maps_touch_range_onto_output_extent(self):
        assert map_to_logical(0, 0, 4095, output_offset=0, output_extent=1920) == 0
        assert map_to_logical(4095, 0, 4095, output_offset=0, output_extent=1920) == 1920
        assert map_to_logical(2048 - 1, 0, 4095, output_offset=0, output_extent=1920) == 960

    def test_offsets_by_output_position(self):
        # A second output starting at logical x=1920.
        assert map_to_logical(0, 0, 4095, output_offset=1920, output_extent=1920) == 1920
        assert map_to_logical(4095, 0, 4095, output_offset=1920, output_extent=1920) == 3840

    def test_degenerate_touch_range_falls_back_to_offset(self):
        assert map_to_logical(50, 100, 100, output_offset=42, output_extent=1920) == 42


class FakeTimer:
    """Records the callback instead of scheduling it on a real thread, so
    debounce tests can fire (or skip) it deterministically."""

    def __init__(self, interval, function, args=()):
        self.interval = interval
        self.function = function
        self.args = args
        self.cancelled = False
        self.started = False

    def start(self):
        self.started = True

    def cancel(self):
        self.cancelled = True

    def fire(self):
        if not self.cancelled:
            self.function(*self.args)


class TestClassifyTap:
    def test_short_move_short_duration_is_tap(self):
        assert classify_tap(2, -3, 0.1, move_threshold=15, long_press_s=0.5) == "tap"

    def test_short_move_long_duration_is_long_tap(self):
        assert classify_tap(0, 0, 0.6, move_threshold=15, long_press_s=0.5) == "long-tap"

    def test_large_move_is_not_a_tap(self):
        assert classify_tap(50, 0, 0.1, move_threshold=15, long_press_s=0.5) is None


class TestTapDebounce:
    def _make_detector(self, config=None):
        dispatched = []
        detector = GestureDetector(
            config or GestureConfig(),
            dispatch=lambda action, delta, touch_xy: dispatched.append(
                (action, delta, touch_xy)
            ),
            get_app_id=lambda: None,
            timer_factory=FakeTimer,
        )
        return detector, dispatched

    def test_lone_tap_dispatches_after_debounce_window_fires(self):
        config = GestureConfig(**{"global": {"1-finger-tap": "forward:click-left"}})
        detector, dispatched = self._make_detector(config)

        detector._process_signal(_TapSignal("tap", 100, 100, 1.0))
        assert dispatched == []  # not dispatched yet -- awaiting the debounce window

        pending = detector._pending_tap
        assert isinstance(pending, _PendingTap)
        pending.timer.fire()

        assert dispatched == [(ForwardClick(button="left"), 0.0, (100, 100))]

    def test_second_tap_within_window_cancels_timer_and_dispatches_double_tap(self):
        config = GestureConfig(
            **{
                "global": {
                    "1-finger-tap": "forward:click-left",
                    "1-finger-double-tap": "forward:click-right",
                }
            }
        )
        detector, dispatched = self._make_detector(config)

        detector._process_signal(_TapSignal("tap", 100, 100, 1.0))
        first_timer = detector._pending_tap.timer
        detector._process_signal(_TapSignal("tap", 105, 98, 1.1))

        assert first_timer.cancelled
        assert detector._pending_tap is None
        assert dispatched == [(ForwardClick(button="right"), 0.0, (105, 98))]

    def test_second_tap_outside_window_is_treated_as_a_new_lone_tap(self):
        config = GestureConfig(
            **{
                "global": {
                    "1-finger-tap": "forward:click-left",
                    "1-finger-double-tap": "forward:click-right",
                }
            }
        )
        detector, dispatched = self._make_detector(config)

        detector._process_signal(_TapSignal("tap", 100, 100, 1.0))
        detector._process_signal(_TapSignal("tap", 100, 100, 2.0))  # well past the window

        assert dispatched == []
        detector._pending_tap.timer.fire()
        assert dispatched == [(ForwardClick(button="left"), 0.0, (100, 100))]

    def test_long_tap_dispatches_immediately(self):
        config = GestureConfig(**{"global": {"1-finger-long-tap": "forward:click-right"}})
        detector, dispatched = self._make_detector(config)

        detector._process_signal(_TapSignal("long-tap", 100, 100, 1.0))

        assert dispatched == [(ForwardClick(button="right"), 0.0, (100, 100))]
        assert detector._pending_tap is None


class TestClassifiers:
    def test_count_fingers(self):
        assert (
            count_active_fingers(
                {
                    0: {
                        "tracking_id": 167,
                        "start_x": 2404,
                        "start_y": 776,
                        "last_x": 1946,
                        "last_y": 717,
                    },
                    1: {
                        "tracking_id": -1,
                        "start_x": 0,
                        "start_y": 0,
                        "last_x": 0,
                        "last_y": 0,
                    },
                    2: {
                        "tracking_id": -1,
                        "start_x": 0,
                        "start_y": 0,
                        "last_x": 0,
                        "last_y": 0,
                    },
                    3: {
                        "tracking_id": -1,
                        "start_x": 0,
                        "start_y": 0,
                        "last_x": 0,
                        "last_y": 0,
                    },
                    4: {
                        "tracking_id": -1,
                        "start_x": 0,
                        "start_y": 0,
                        "last_x": 0,
                        "last_y": 0,
                    },
                    5: {
                        "tracking_id": -1,
                        "start_x": 0,
                        "start_y": 0,
                        "last_x": 0,
                        "last_y": 0,
                    },
                    6: {
                        "tracking_id": -1,
                        "start_x": 0,
                        "start_y": 0,
                        "last_x": 0,
                        "last_y": 0,
                    },
                    7: {
                        "tracking_id": -1,
                        "start_x": 0,
                        "start_y": 0,
                        "last_x": 0,
                        "last_y": 0,
                    },
                    8: {
                        "tracking_id": -1,
                        "start_x": 0,
                        "start_y": 0,
                        "last_x": 0,
                        "last_y": 0,
                    },
                    9: {
                        "tracking_id": -1,
                        "start_x": 0,
                        "start_y": 0,
                        "last_x": 0,
                        "last_y": 0,
                    },
                }
            )
            == 1
        )
