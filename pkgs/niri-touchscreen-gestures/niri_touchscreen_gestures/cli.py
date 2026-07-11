"""Command-line interface and main loop."""

from __future__ import annotations

import argparse
import logging
import os
import subprocess
import sys
from cmath import log

import evdev

from .config import GestureConfig
from .detector import find_touchscreen

logger = logging.getLogger(__name__)


def run_commands(cmds: list[list[str]]) -> None:
    for cmd in cmds:
        if not cmd:
            continue
        try:
            subprocess.run(cmd, check=False)
        except Exception as exc:
            logger.info(
                f"niri-touchscreen-gestures: failed to run {cmd}: {exc}",
            )


def get_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Touchscreen gesture detector for niri"
    )
    parser.add_argument(
        "--config",
        required=True,
        help="Path to TOML config file",
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


def process_args(args: argparse.Namespace):
    if not os.path.exists(args.config):
        raise FileNotFoundError(f"Config not found: {args.config}")
    logger.info(f"niri-touchscreen-gestures: using config {args.config}")
    config = GestureConfig.from_toml(args.config)

    device_path = args.device or find_touchscreen()
    if not device_path:
        raise RuntimeError(
            "No touchscreen found. Pass --device /dev/input/eventN explicitly.",
        )
    logger.info(f"niri-touchscreen-gestures: using device {device_path}")
    try:
        dev = evdev.InputDevice(device_path)
    except PermissionError:
        raise PermissionError(
            f"Permission denied opening {device_path}.\n"
            "Add your user to the 'input' group.",
        )
    logger.info(f"niri-touchscreen-gestures: opened device {device_path}")

    logger.info(f"niri-touchscreen-gestures: listening on {device_path}")
    return config, dev, args.threshold
