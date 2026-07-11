"""Pydantic configuration model for gesture mappings."""

from __future__ import annotations

from typing import Any, Dict, List

import tomllib
from pydantic import BaseModel, Field


class GestureConfig(BaseModel):
    """Configuration mapping gesture keys (e.g. "3-finger-up") to lists of
    command arrays. Any key is accepted; values must be arrays of string arrays.
    """

    gestures: Dict[str, List[List[str]]] = Field(default_factory=dict)

    model_config = {"extra": "allow"}

    @classmethod
    def from_toml(cls, path: str) -> GestureConfig:
        with open(path, "rb") as f:
            data: Dict[str, Any] = tomllib.load(f)
        return cls(gestures=data)

    def get(self, key: str) -> List[List[str]] | None:
        return self.gestures.get(key)
