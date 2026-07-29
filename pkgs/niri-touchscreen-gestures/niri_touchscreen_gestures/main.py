import logging
from collections.abc import Callable
from typing import Any

from niri_touchscreen_gestures import __version__, forwarder, nirictl
from niri_touchscreen_gestures.actions import ForwardClick, ForwardScroll, GestureAction
from niri_touchscreen_gestures.argparser import get_parser, process_args
from niri_touchscreen_gestures.coords import map_to_logical
from niri_touchscreen_gestures.detector.gestures import GestureDetector
from niri_touchscreen_gestures.logger import set_logging

logger = logging.getLogger(__name__)


def resolve_touch_output(
    outputs: dict[str, Any], requested_name: str | None
) -> dict[str, Any]:
    """Returns the `logical` geometry of the output the touchscreen maps to."""
    if requested_name is not None:
        output = outputs.get(requested_name)
        if output is None or output.get("logical") is None:
            raise RuntimeError(f"Output {requested_name!r} not found or not enabled")
        return output["logical"]

    enabled = {name: o for name, o in outputs.items() if o.get("logical") is not None}
    if len(enabled) == 1:
        return next(iter(enabled.values()))["logical"]
    raise RuntimeError(
        f"Expected exactly one enabled output, found {list(enabled)}. "
        "Pass --touch-output NAME to pick which one the touchscreen maps to."
    )


def make_dispatch(
    touch_x_range: tuple[int, int],
    touch_y_range: tuple[int, int],
    output_logical: dict[str, Any],
) -> Callable[[GestureAction, float, tuple[int, int] | None], None]:
    def dispatch(
        action: GestureAction, delta: float, touch_xy: tuple[int, int] | None
    ) -> None:
        logger.info(
            f"niri-touchscreen-gestures: dispatching {action=} {delta=} {touch_xy=}"
        )
        if isinstance(action, ForwardClick):
            touch_x, touch_y = touch_xy if touch_xy is not None else (0, 0)
            x = map_to_logical(
                touch_x, *touch_x_range, output_logical["x"], output_logical["width"]
            )
            y = map_to_logical(
                touch_y, *touch_y_range, output_logical["y"], output_logical["height"]
            )
            forwarder.send_click_at(action.button, x, y)
        elif isinstance(action, ForwardScroll):
            forwarder.send_scroll(delta)
        else:
            nirictl.send_niri_action(action)

    return dispatch


def get_focused_app_id() -> str | None:
    window = nirictl.get_focused_window()
    return window.get("app_id") if window else None


def main_runtime() -> None:
    set_logging()
    logger.info("niri-touchscreen-gestures: starting")
    logger.info(f"version: {__version__}")
    runtime = process_args(get_parser().parse_args())

    output_logical = resolve_touch_output(nirictl.get_outputs(), runtime.touch_output)

    detector = GestureDetector(
        runtime.config,
        dispatch=make_dispatch(
            runtime.touch_x_range, runtime.touch_y_range, output_logical
        ),
        get_app_id=get_focused_app_id,
        threshold=runtime.threshold,
    )

    for ev in runtime.device.read_loop():
        detector.handle_event(ev)


if __name__ == "__main__":
    main_runtime()
