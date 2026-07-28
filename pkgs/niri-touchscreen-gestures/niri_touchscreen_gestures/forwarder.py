"""Forwards synthetic input to whatever window currently has compositor
focus, via wlrctl (wlr-virtual-pointer-unstable-v1 / virtual-keyboard-unstable-v1).
Niri implements both protocols, so no root daemon / uinput access is needed."""

import logging
import subprocess
from typing import Literal

logger = logging.getLogger(__name__)


# Larger than any realistic logical-layout size, to reliably clamp the
# pointer to the logical origin (0, 0) regardless of where it currently is.
_WARP_MAGNITUDE = 100_000


def send_click_at(button: Literal["left", "right"], x: int, y: int) -> None:
    """Move the pointer to the absolute logical coordinate (x, y) and click.

    wlrctl's `pointer move` is relative-only and there's no way to query the
    pointer's current position, so we warp it to the logical origin first
    (niri places the primary output there and arranges outputs contiguously,
    so this reliably clamps regardless of the pointer's prior position) and
    then move by the exact target offset.
    """
    logger.info(f"niri-touchscreen-gestures: forwarding click {button=} at ({x}, {y})")
    subprocess.run(
        ["wlrctl", "pointer", "move", str(-_WARP_MAGNITUDE), str(-_WARP_MAGNITUDE)],
        check=True,
    )
    subprocess.run(["wlrctl", "pointer", "move", str(x), str(y)], check=True)
    subprocess.run(["wlrctl", "pointer", "click", button], check=True)


def send_scroll(dy: float) -> None:
    logger.info(f"niri-touchscreen-gestures: forwarding scroll {dy=}")
    subprocess.run(["wlrctl", "pointer", "scroll", str(dy)], check=True)
