"""Command-line interface and main loop."""

from __future__ import annotations

import argparse
import logging
import os

import evdev

from .config import GestureConfig
from .detector.touchscreen_identifier import identify_touchscreen_via_evdev

logger = logging.getLogger(__name__)


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
    return parser


def process_args(
    args: argparse.Namespace,
) -> tuple[GestureConfig, evdev.InputDevice, int]:
    if args.config is None:
        config = GestureConfig(
            gestures={
                "3-finger-up": "FocusWorkspaceDown",
                "3-finger-down": "FocusWorkspaceUp",
                "3-finger-left": "FocusColumnRight",
                "3-finger-right": "FocusColumnLeft",
                "4-finger-up": "ToggleOverview",
                "4-finger-down": "ToggleOverview",
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
    return config, device, args.threshold
