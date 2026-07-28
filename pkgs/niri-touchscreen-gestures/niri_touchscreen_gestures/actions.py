"""Gesture action model: either a niri IPC action, or synthetic input forwarded
to whatever window currently has compositor focus."""

from __future__ import annotations

from typing import Literal, Union

from pydantic import BaseModel

from niri_touchscreen_gestures.nirictl import SupportedActions


class ForwardClick(BaseModel):
    kind: Literal["click"] = "click"
    button: Literal["left", "right"]


class ForwardScroll(BaseModel):
    kind: Literal["scroll"] = "scroll"


GestureAction = Union[SupportedActions, ForwardClick, ForwardScroll]

_FORWARD_CLICK_PREFIX = "forward:click-"
_FORWARD_SCROLL = "forward:scroll"


def parse_action(raw: str) -> GestureAction:
    """Parse a config string into a GestureAction.

    "forward:click-left" / "forward:click-right" -> ForwardClick
    "forward:scroll" -> ForwardScroll
    anything else -> treated as a niri SupportedActions string (unchanged
    behavior for existing configs).
    """
    if raw == _FORWARD_SCROLL:
        return ForwardScroll()
    if raw.startswith(_FORWARD_CLICK_PREFIX):
        button = raw[len(_FORWARD_CLICK_PREFIX) :]
        if button not in ("left", "right"):
            raise ValueError(f"Unknown forward click button: {raw!r}")
        return ForwardClick(button=button)  # type: ignore[arg-type]
    return raw  # type: ignore[return-value]
