import logging

from niri_touchscreen_gestures.argparser import get_parser, process_args
from niri_touchscreen_gestures.detector.gestures import GestureDetector
from niri_touchscreen_gestures.nirictl import send_niri_action

logging.basicConfig(level=logging.INFO)

logger = logging.getLogger(__name__)


def main_runtime() -> None:
    logger.info("niri-touchscreen-gestures: starting")
    config, dev, threshold = process_args(get_parser().parse_args())

    detector = GestureDetector(
        config,
        threshold=threshold,
    )

    for ev in dev.read_loop():
        result = detector.handle_event(ev)
        if result:
            logger.info(f"niri-touchscreen-gestures: event {ev}, result {result}")
            send_niri_action(result)


if __name__ == "__main__":
    main_runtime()
