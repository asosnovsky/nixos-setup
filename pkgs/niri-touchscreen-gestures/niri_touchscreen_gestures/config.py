"""Pydantic configuration model for gesture mappings."""

from __future__ import annotations

from typing import Any

import tomllib
from pydantic import BaseModel, Field

from niri_touchscreen_gestures.nirictl import SupportedActions


class GestureConfig(BaseModel):
    """Configuration mapping gesture keys (e.g. "3-finger-up") to lists of
    command arrays. Any key is accepted; values must be arrays of string arrays.
    """

    gestures: dict[str, SupportedActions] = Field(default_factory=dict)

    model_config = {"extra": "allow"}

    @classmethod
    def from_toml(cls, path: str) -> GestureConfig:
        with open(path, "rb") as f:
            data: dict[str, Any] = tomllib.load(f)
        return cls(gestures=data)

    def get(self, key: str) -> SupportedActions | None:
        return self.gestures.get(key)
