"""Pydantic configuration model for gesture mappings."""

from __future__ import annotations

from typing import Any

import tomllib
from pydantic import BaseModel, Field

from niri_touchscreen_gestures.actions import GestureAction, parse_action


class GestureConfig(BaseModel):
    """Configuration mapping gesture keys (e.g. "3-finger-up") to actions.

    Rules live under two tables:
      - `global`: fallback rules, used when no focused-app-specific rule matches.
      - `apps."<app-id>"`: rules that only apply while that app is focused.

    App-specific rules take priority over global ones for the same key.
    """

    global_: dict[str, str] = Field(default_factory=dict, alias="global")
    apps: dict[str, dict[str, str]] = Field(default_factory=dict)

    model_config = {"populate_by_name": True}

    @classmethod
    def from_toml(cls, path: str) -> GestureConfig:
        with open(path, "rb") as f:
            data: dict[str, Any] = tomllib.load(f)
        return cls(**data)

    def resolve(self, key: str, app_id: str | None) -> GestureAction | None:
        """Resolve a gesture key to an action, preferring the focused app's
        rules over the global fallback."""
        if app_id and (raw := self.apps.get(app_id, {}).get(key)):
            return parse_action(raw)
        if raw := self.global_.get(key):
            return parse_action(raw)
        return None
