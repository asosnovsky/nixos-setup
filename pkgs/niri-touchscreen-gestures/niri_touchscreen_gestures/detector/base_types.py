from typing import Literal, TypedDict

from pydantic import BaseModel, Field

FingerNumber = int

SwipeDirection = Literal["up", "down", "left", "right"]


class Slot(TypedDict):
    """Per-slot tracking information."""

    tracking_id: int
    start_x: int
    start_y: int
    last_x: int
    last_y: int


class DetectorState(BaseModel):
    """Immutable snapshot of detector state."""

    slots: dict[FingerNumber, Slot] = Field(default_factory=dict)
    current_slot: FingerNumber = FingerNumber(0)

    model_config = {"frozen": True}
