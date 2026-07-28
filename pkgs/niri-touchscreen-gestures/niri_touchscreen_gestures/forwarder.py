"""Forwards synthetic input to whatever window currently has compositor
focus, via wlrctl (wlr-virtual-pointer-unstable-v1 / virtual-keyboard-unstable-v1).
Niri implements both protocols, so no root daemon / uinput access is needed."""

import logging
import subprocess
from typing import Literal

logger = logging.getLogger(__name__)


def send_click(button: Literal["left", "right"]) -> None:
    logger.info(f"niri-touchscreen-gestures: forwarding click {button=}")
    subprocess.run(["wlrctl", "pointer", "click", button], check=True)


def send_scroll(dy: float) -> None:
    logger.info(f"niri-touchscreen-gestures: forwarding scroll {dy=}")
    subprocess.run(["wlrctl", "pointer", "scroll", str(dy)], check=True)
