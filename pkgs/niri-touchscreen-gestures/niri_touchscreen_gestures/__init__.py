import os
from datetime import datetime, timezone

__version__ = os.environ.get(
    "BUILD_VERSION",
    datetime.now(timezone.utc).strftime("%Y.%m.%d%H%M%S"),
)


if __name__ == "__main__":
    print(__version__)
