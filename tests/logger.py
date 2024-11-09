import logging
from typing import Optional
import sys
from datetime import datetime

class ColoredFormatter(logging.Formatter):
    """Custom formatter with colors and structured output"""
    
    # ANSI escape sequences for colors
    COLORS = {
        'DEBUG': '\033[36m',     # Cyan
        'INFO': '\033[32m',      # Green
        'WARNING': '\033[33m',   # Yellow
        'ERROR': '\033[31m',     # Red
        'CRITICAL': '\033[41m',  # Red background
        'RESET': '\033[0m'       # Reset color
    }
    
    def __init__(self, use_colors: bool = True):
        super().__init__()
        self.use_colors = use_colors

    def format(self, record: logging.LogRecord) -> str:
        # Create timestamp
        timestamp = datetime.fromtimestamp(record.created).strftime('%Y-%m-%d %H:%M:%S')
        
        # Get the appropriate color code
        if self.use_colors:
            color = self.COLORS.get(record.levelname, self.COLORS['RESET'])
            reset = self.COLORS['RESET']
        else:
            color = ''
            reset = ''
        
        # Format the basic message
        message = f"{color}{timestamp} | {record.levelname:<8} | {record.name:<15} | {record.message}{reset}"
        
        # If there's an exception, format it nicely
        if record.exc_info:
            exception_lines = self.formatException(record.exc_info).split('\n')
            formatted_exception = '\n'.join(
                f"{' ' * 32}{line}" for line in exception_lines
            )
            message = f"{message}\n{formatted_exception}"
        
        # Add separator lines for ERROR and CRITICAL messages
        if record.levelno >= logging.ERROR:
            separator = f"{color}{'=' * 80}{reset}"
            message = f"{separator}\n{message}\n{separator}"
            
        return message

def setup_logging(
    level: int = logging.INFO,
    use_colors: bool = True,
    log_file: Optional[str] = None
) -> logging.Logger:
    """
    Set up logging with improved formatting
    
    Args:
        level: The logging level to use
        use_colors: Whether to use colored output
        log_file: Optional file path to save logs
    
    Returns:
        logging.Logger: Configured logger instance
    """
    # Create logger
    logger = logging.getLogger()
    logger.setLevel(level)
    
    # Remove existing handlers
    for handler in logger.handlers[:]:
        logger.removeHandler(handler)
    
    # Console handler
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(ColoredFormatter(use_colors=use_colors))
    logger.addHandler(console_handler)
    
    # File handler if specified
    if log_file:
        file_handler = logging.FileHandler(log_file)
        file_handler.setFormatter(ColoredFormatter(use_colors=False))
        logger.addHandler(file_handler)
    
    return logger

logger = setup_logging(level=logging.INFO, use_colors=True)