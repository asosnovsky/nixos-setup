"""Command-line interface and main loop."""

from __future__ import annotations

import argparse
import logging
import os
from dataclasses import dataclass

import evdev

from .config import GestureConfig
from .detector.touchscreen_identifier import identify_touchscreen_via_evdev

logger = logging.getLogger(__name__)


@dataclass
class RuntimeConfig:
    config: GestureConfig
    device: evdev.InputDevice
    threshold: int
    touch_output: str | None
    touch_x_range: tuple[int, int]
    touch_y_range: tuple[int, int]


def get_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Touchscreen gesture detector for niri"
    )
    parser.add_argument(
        "--config",
        default=None,
        help="Path to TOML config file (optional - uses built-in defaults)",
    )
    parser.add_argument(
        "--threshold",
        type=int,
        default=60,
        help="Minimum pixels of movement to register a swipe (default: 60)",
    )
    parser.add_argument(
        "--device",
        help="Explicit evdev device path (default: auto-detect first touchscreen)",
    )
    parser.add_argument(
        "--touch-output",
        default=None,
        help=(
            "Name of the niri output (e.g. eDP-1) the touchscreen is mapped to "
            "(used to place forwarded clicks at the tapped location). Required "
            "only if more than one niri output is connected."
        ),
    )
    return parser


def get_touch_absinfo(
    device: evdev.InputDevice,
) -> tuple[tuple[int, int], tuple[int, int]]:
    """Returns ((x_min, x_max), (y_min, y_max)) for the device's touch axes."""
    absinfo = dict(device.capabilities(absinfo=True).get(evdev.ecodes.EV_ABS, []))
    x = absinfo.get(evdev.ecodes.ABS_MT_POSITION_X) or absinfo.get(evdev.ecodes.ABS_X)
    y = absinfo.get(evdev.ecodes.ABS_MT_POSITION_Y) or absinfo.get(evdev.ecodes.ABS_Y)
    if x is None or y is None:
        raise RuntimeError(f"{device.path} doesn't report an ABS_MT_POSITION_X/Y range")
    return (x.min, x.max), (y.min, y.max)


def process_args(args: argparse.Namespace) -> RuntimeConfig:
    if args.config is None:
        config = GestureConfig(
            **{
                "global": {
                    "3-finger-up": "FocusWorkspaceDown",
                    "3-finger-down": "FocusWorkspaceUp",
                    "3-finger-left": "FocusColumnRight",
                    "3-finger-right": "FocusColumnLeft",
                    "4-finger-up": "ToggleOverview",
                    "4-finger-down": "ToggleOverview",
                }
            }
        )
    elif not os.path.exists(args.config):
        raise FileNotFoundError(f"Config not found: {args.config}")
    else:
        logger.info(f"niri-touchscreen-gestures: using config {args.config}")
        config = GestureConfig.from_toml(args.config)

    if args.device is None:
        devices = list(identify_touchscreen_via_evdev())
        if len(devices) > 1:
            raise RuntimeError(
                f"Multiple touchscreens found ({devices=}). Pass --device /dev/input/eventN explicitly.",
            )
        if len(devices) == 0:
            raise RuntimeError(
                "No touchscreen found. Pass --device /dev/input/eventN explicitly.",
            )
        device = devices[0]
    else:
        device = evdev.InputDevice(args.device)

    logger.info(f"niri-touchscreen-gestures: using device {device.path}")
    touch_x_range, touch_y_range = get_touch_absinfo(device)

    return RuntimeConfig(
        config=config,
        device=device,
        threshold=args.threshold,
        touch_output=args.touch_output,
        touch_x_range=touch_x_range,
        touch_y_range=touch_y_range,
    )
