import logging

from niri_touchscreen_gestures import forwarder, nirictl
from niri_touchscreen_gestures.actions import ForwardClick, ForwardScroll, GestureAction
from niri_touchscreen_gestures.argparser import get_parser, process_args
from niri_touchscreen_gestures.detector.gestures import GestureDetector

logging.basicConfig(level=logging.INFO)

logger = logging.getLogger(__name__)


def dispatch(action: GestureAction, delta: float) -> None:
    logger.info(f"niri-touchscreen-gestures: dispatching {action=} {delta=}")
    if isinstance(action, ForwardClick):
        forwarder.send_click(action.button)
    elif isinstance(action, ForwardScroll):
        forwarder.send_scroll(delta)
    else:
        nirictl.send_niri_action(action)


def get_focused_app_id() -> str | None:
    window = nirictl.get_focused_window()
    return window.get("app_id") if window else None


def main_runtime() -> None:
    logger.info("niri-touchscreen-gestures: starting")
    config, dev, threshold = process_args(get_parser().parse_args())

    detector = GestureDetector(
        config,
        dispatch=dispatch,
        get_app_id=get_focused_app_id,
        threshold=threshold,
    )

    for ev in dev.read_loop():
        detector.handle_event(ev)


if __name__ == "__main__":
    main_runtime()
