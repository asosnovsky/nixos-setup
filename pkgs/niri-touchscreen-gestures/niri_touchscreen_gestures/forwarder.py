"""Forwards synthetic input to whatever window currently has compositor
focus. Clicks are forwarded via ydotool (uinput), which requires ydotoold to
be running with --touch-on so its virtual device exposes absolute axes.
Scrolling is forwarded via wlrctl (wlr-virtual-pointer-unstable-v1), which
ydotool has no equivalent subcommand for."""

import logging
import subprocess
from typing import Literal

logger = logging.getLogger(__name__)

_CLICK_CODES: dict[Literal["left", "right"], str] = {
    "left": "0xC0",
    "right": "0xC1",
}


def _run_subprocess(*args: str) -> None:
    logger.info(f"niri-touchscreen-gestures: running subprocess {' '.join(args)}")
    subprocess.run(list(args), check=True)


def send_click_at(button: Literal["left", "right"], x: int, y: int) -> None:
    logger.info(f"niri-touchscreen-gestures: forwarding click {button=} at ({x}, {y})")
    _run_subprocess(
        "ydotool",
        "mousemove",
        "--absolute",
        "--",
        str(x),
        str(y),
    )
    _run_subprocess("ydotool", "click", _CLICK_CODES[button])


def send_scroll(dy: float) -> None:
    logger.info(f"niri-touchscreen-gestures: forwarding scroll {dy=}")
    _run_subprocess("wlrctl", "pointer", "scroll", str(dy))
