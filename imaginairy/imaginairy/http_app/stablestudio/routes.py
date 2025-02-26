"""Input validation for the stablestudio API"""

import sys
import re
from typing import Optional, Dict, Any, List
import psutil
import json

class InputValidator:
    # Maximum allowed prompt length (in characters)
    MAX_PROMPT_LENGTH = 10000  # Reasonable limit for normal use
    # Maximum allowed total request size (in bytes)
    MAX_REQUEST_SIZE = 1024 * 1024  # 1MB
    # Maximum allowed memory usage increase during processing (in bytes)
    MAX_MEMORY_INCREASE = 100 * 1024 * 1024  # 100MB

    @staticmethod
    def _get_current_memory_usage() -> int:
        """Get current process memory usage in bytes"""
        process = psutil.Process()
        return process.memory_info().rss

    @staticmethod
    def validate_prompt_length(text: Optional[str]) -> bool:
        """
        Validate that the prompt text length is within acceptable limits.
        
        Args:
            text: The prompt text to validate
            
        Returns:
            bool: True if valid
            
        Raises:
            ValueError: If the prompt is too long or contains suspicious patterns
        """
        if not text:
            return True

        # Check raw length
        if len(text) > InputValidator.MAX_PROMPT_LENGTH:
            raise ValueError(
                f"Prompt text exceeds maximum allowed length of {InputValidator.MAX_PROMPT_LENGTH} characters. "
                f"Current length: {len(text)} characters."
            )

        # Check for suspicious repetition patterns
        pattern = re.compile(r'(.+?)\1{100,}')  # Detect strings repeated >100 times
        if pattern.search(text):
            raise ValueError(
                "Prompt contains suspicious repetition patterns that may indicate an attack attempt."
            )

        return True

    @staticmethod
    def validate_request_payload(payload: Dict[str, Any]) -> bool:
        """
        Validate the complete request payload.
        
        Args:
            payload: The complete request payload
            
        Returns:
            bool: True if valid
            
        Raises:
            ValueError: If the payload is invalid or suspicious
        """
        # Check total request size
        request_size = len(json.dumps(payload).encode('utf-8'))
        if request_size > InputValidator.MAX_REQUEST_SIZE:
            raise ValueError(
                f"Request size exceeds maximum allowed size of {InputValidator.MAX_REQUEST_SIZE} bytes. "
                f"Current size: {request_size} bytes."
            )

        # Track memory usage before processing
        initial_memory = InputValidator._get_current_memory_usage()

        try:
            # Validate all prompts in the request
            if 'input' in payload and 'prompts' in payload['input']:
                prompts: List[Dict[str, Any]] = payload['input']['prompts']
                for prompt in prompts:
                    if 'text' in prompt:
                        InputValidator.validate_prompt_length(prompt['text'])

                        # Check memory usage after each prompt validation
                        current_memory = InputValidator._get_current_memory_usage()
                        memory_increase = current_memory - initial_memory
                        if memory_increase > InputValidator.MAX_MEMORY_INCREASE:
                            raise ValueError(
                                f"Processing request would exceed maximum allowed memory increase of "
                                f"{InputValidator.MAX_MEMORY_INCREASE} bytes. "
                                f"Current increase: {memory_increase} bytes."
                            )
        except Exception as e:
            # Ensure we don't leak memory even if validation fails
            import gc
            gc.collect()
            raise e

        return True