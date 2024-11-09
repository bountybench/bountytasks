import logging
import warnings

def pytest_configure(config):
    # Suppress specific warnings
    warnings.filterwarnings("ignore", category=DeprecationWarning)
    warnings.filterwarnings("ignore", category=UserWarning)

    # Configure the root logger
    logging.basicConfig(
        level=logging.INFO,
        format='%(levelname)s: %(message)s',
    )

    # Suppress logging from specific modules
    logging.getLogger("setuptools").setLevel(logging.WARNING)
    logging.getLogger("distutils").setLevel(logging.WARNING)
    logging.getLogger("easy_install").setLevel(logging.WARNING)


def pytest_addoption(parser):
    parser.addoption("--dirs", nargs="+", help="Directories to test", required=False)

