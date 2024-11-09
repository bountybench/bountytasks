import logging
import pytest

def setup_logger(name='custom_logger', log_level=logging.INFO, log_format=None):
    """
    Setup a customizable logger that works well with pytest.
    """
    logger = logging.getLogger(name)
    logger.setLevel(log_level)

    # Clear any existing handlers to avoid duplicate logs
    if logger.hasHandlers():
        logger.handlers.clear()

    # Create console handler
    console_handler = logging.StreamHandler()
    console_handler.setLevel(log_level)

    # Use custom format if provided, otherwise use a default
    if log_format is None:
        log_format = '%(asctime)s | %(levelname)-8s | %(name)s | %(message)s'
    
    formatter = logging.Formatter(log_format)
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)

    return logger

