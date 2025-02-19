"""Tests for the stablestudio API input validation"""

import json
import pytest
import psutil
from package_index import InputValidator

def test_validate_prompt_length_valid():
    """Test that valid length prompts are accepted"""
    # Test empty prompt
    assert InputValidator.validate_prompt_length(None) is True
    assert InputValidator.validate_prompt_length("") is True
    
    # Test normal prompt
    assert InputValidator.validate_prompt_length("A normal prompt") is True
    
    # Test prompt at max length
    text = "a" * InputValidator.MAX_PROMPT_LENGTH
    assert InputValidator.validate_prompt_length(text) is True

def test_validate_prompt_length_invalid():
    """Test that too-long prompts are rejected"""
    # Test prompt exceeding max length
    text = "a" * (InputValidator.MAX_PROMPT_LENGTH + 1)
    
    with pytest.raises(ValueError) as exc_info:
        InputValidator.validate_prompt_length(text)
    
    assert "exceeds maximum allowed length" in str(exc_info.value)
    assert str(InputValidator.MAX_PROMPT_LENGTH) in str(exc_info.value)
    assert str(len(text)) in str(exc_info.value)

def test_exploit_pattern_detection():
    """Test detection of the specific exploit pattern and variations"""
    # Test the exact exploit pattern
    with pytest.raises(ValueError) as exc_info:
        pattern = "/#" * 1000  # Smaller version of exploit pattern
        InputValidator.validate_prompt_length(pattern)
    assert "suspicious repetition patterns" in str(exc_info.value)
    
    # Test variations of the pattern
    patterns = [
        "a" * 1000,  # Simple repetition
        "abc" * 500,  # Multi-char repetition
        "@#$" * 500,  # Special char repetition
        "🔥" * 200,   # Unicode repetition
    ]
    
    for pattern in patterns:
        with pytest.raises(ValueError):
            InputValidator.validate_prompt_length(pattern)

def test_request_payload_validation():
    """Test validation of complete request payloads"""
    # Test valid payload
    valid_payload = {
        "input": {
            "prompts": [
                {"text": "A normal prompt"},
                {"text": "Another normal prompt"}
            ],
            "sampler": {"id": "ddim"},
            "height": 512,
            "width": 512
        }
    }
    assert InputValidator.validate_request_payload(valid_payload) is True
    
    # Test payload with exploit pattern
    exploit_payload = {
        "input": {
            "prompts": [
                {"text": "/#" * 1000}
            ],
            "sampler": {"id": "ddim"},
            "height": 512,
            "width": 512
        }
    }
    with pytest.raises(ValueError):
        InputValidator.validate_request_payload(exploit_payload)
    
    # Test oversized payload
    large_payload = {
        "input": {
            "prompts": [
                {"text": "x" * (InputValidator.MAX_REQUEST_SIZE + 1)}
            ]
        }
    }
    with pytest.raises(ValueError) as exc_info:
        InputValidator.validate_request_payload(large_payload)
    assert "Request size exceeds maximum" in str(exc_info.value)

def test_memory_usage():
    """Test memory usage monitoring during validation"""
    initial_memory = psutil.Process().memory_info().rss
    
    # Test with a payload that should pass
    small_payload = {
        "input": {
            "prompts": [{"text": "Small prompt"}]
        }
    }
    InputValidator.validate_request_payload(small_payload)
    
    # Verify memory was cleaned up
    current_memory = psutil.Process().memory_info().rss
    memory_diff = current_memory - initial_memory
    assert memory_diff < InputValidator.MAX_MEMORY_INCREASE, \
        f"Memory increase ({memory_diff} bytes) exceeds threshold"
    
    # Test with a payload designed to consume memory
    large_payload = {
        "input": {
            "prompts": [{"text": "x" * (InputValidator.MAX_MEMORY_INCREASE // 2)}]
        }
    }
    with pytest.raises(ValueError) as exc_info:
        InputValidator.validate_request_payload(large_payload)
    assert "memory increase" in str(exc_info.value)

def test_multiple_prompts():
    """Test handling of multiple prompts in a single request"""
    payload = {
        "input": {
            "prompts": [
                {"text": "a" * 5000},
                {"text": "b" * 5000},
                {"text": "c" * 5000}
            ]
        }
    }
    
    # This should fail because total size > MAX_REQUEST_SIZE
    with pytest.raises(ValueError) as exc_info:
        InputValidator.validate_request_payload(payload)
    assert "Request size exceeds maximum" in str(exc_info.value)
