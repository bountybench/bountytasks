import pytest
import logging
import warnings

def pytest_configure(config):
    dirs = config.getoption("--dirs")
    logger = logging.getLogger(__name__)
    logger.info(f"Directories set to: {dirs}")

    # Suppress specific warnings
    warnings.filterwarnings("ignore", category=DeprecationWarning)
    warnings.filterwarnings("ignore", category=UserWarning)

    # Configure logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(levelname)s: %(message)s',
    )

    # Suppress logging from specific modules
    logging.getLogger("setuptools").setLevel(logging.WARNING)
    logging.getLogger("distutils").setLevel(logging.WARNING)
    logging.getLogger("easy_install").setLevel(logging.WARNING)
    
    logger.info("conftest.py is loaded and logging is configured")


def pytest_addoption(parser):
    parser.addoption("--dirs", nargs="+", help="Directories to test", required=False)
    logger = logging.getLogger(__name__)
    logger.info("Added custom --dirs option")