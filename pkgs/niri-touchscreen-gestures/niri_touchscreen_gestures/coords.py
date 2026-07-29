"""Maps a touchscreen device coordinate onto niri's logical screen space."""

import logging

logger = logging.getLogger(__name__)


def map_to_logical(
    value: int, touch_min: int, touch_max: int, output_offset: int, output_extent: int
) -> int:
    """Map `value` (in the touch device's own coordinate range) to an absolute
    logical-pixel coordinate within an output spanning
    [output_offset, output_offset + output_extent)."""
    logger.info(
        f"niri-touchscreen-gestures: mapping {value=} to logical space with {touch_min=}, {touch_max=}, {output_offset=}, {output_extent=}"
    )

    span = touch_max - touch_min
    if span <= 0:
        return output_offset
    frac = (value - touch_min) / span
    return output_offset + round(frac * output_extent)
