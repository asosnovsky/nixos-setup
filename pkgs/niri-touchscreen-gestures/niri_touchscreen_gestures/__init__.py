"""niri-touchscreen-gestures — detect multi-finger touchscreen swipes and dispatch niri actions."""

__version__ = "0.1.0"


import logging

from niri_touchscreen_gestures.cli import get_parser, process_args, run_commands
from niri_touchscreen_gestures.detector import GestureDetector

logging.basicConfig(level=logging.INFO)

logger = logging.getLogger(__name__)


def run() -> None:
    logger.info("niri-touchscreen-gestures: starting")
    config, dev, threshold = process_args(get_parser().parse_args())

    detector = GestureDetector(
        config,
        threshold=threshold,
    )

    for ev in dev.read_loop():
        result = detector.handle_event(ev)
        if result:
            logger.info(f"niri-touchscreen-gestures: executing {result}")
            run_commands(result)
