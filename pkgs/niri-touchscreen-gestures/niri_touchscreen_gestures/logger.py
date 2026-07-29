import logging


def set_logging(level: int = logging.INFO) -> None:
    logging.basicConfig(
        level=level,
        format="%(asctime)s|%(levelname)s|> %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
