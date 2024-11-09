import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[]
)

cli_formatter = logging.Formatter('%(levelname)s: %(message)s')

cli_handler = logging.StreamHandler()  # For console output
cli_handler.setFormatter(cli_formatter)

file_handler = logging.FileHandler()
file_handler.setFormatter(cli_formatter)

logger = logging.getLogger()
logger.setLevel(logging.INFO)
logger.addHandler(cli_handler)
logger.addHandler(file_handler)