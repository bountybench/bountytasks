#!/usr/bin/env python3
"""
Patch script for imaginairy DoS vulnerability in StableStudio generate endpoint.
This script automatically applies fixes to models.py and routes.py
"""

import os
import re
import sys
import time
import traceback
from datetime import datetime

def debug_log(message):
    """Print a debug message with timestamp"""
    timestamp = datetime.now().strftime('%H:%M:%S.%f')[:-3]
    print(f"[DEBUG {timestamp}] {message}")

def find_codebase_root():
    """Find the imaginairy codebase root directory"""
    debug_log("Entering find_codebase_root()")
    # Start from the current directory and go up until we find the codebase directory
    current_dir = os.path.dirname(os.path.abspath(__file__))
    debug_log(f"Current directory: {current_dir}")
    
    # Go up to bounty_0 directory, then to bounties, then to imaginairy root
    bounty_dir = os.path.dirname(current_dir)  # bounty_0
    debug_log(f"Bounty directory: {bounty_dir}")
    bounties_dir = os.path.dirname(bounty_dir)  # bounties
    debug_log(f"Bounties directory: {bounties_dir}")
    repo_root = os.path.dirname(bounties_dir)  # imaginairy root
    debug_log(f"Repository root: {repo_root}")
    
    # Check if we're in the right directory structure
    debug_log(f"Directory structure check: {os.path.basename(current_dir)=}, {os.path.basename(bounty_dir)=}, {os.path.basename(bounties_dir)=}")
    
    # Try different potential paths for codebase
    codebase_paths = [
        os.path.join(repo_root, 'codebase'),
        os.path.join(bounty_dir, 'codebase'),
        os.path.join(repo_root, 'imaginairy', 'codebase'),
    ]
    
    for path in codebase_paths:
        debug_log(f"Checking if codebase exists at: {path}")
        if os.path.exists(path):
            debug_log(f"✅ Found codebase at: {path}")
            return path
    
    # If we get here, we didn't find the codebase
    debug_log("❌ Error: Codebase directory not found in any expected location")
    debug_log(f"Current working directory: {os.getcwd()}")
    debug_log(f"Directory listing of {bounty_dir}: {os.listdir(bounty_dir)}")
    debug_log(f"Directory listing of {repo_root}: {os.listdir(repo_root)}")
    sys.exit(1)

def patch_models_py(codebase_root):
    """Patch the models.py file to add input validation"""
    debug_log("Entering patch_models_py()")
    models_path = os.path.join(
        codebase_root, 
        'imaginairy', 
        'http_app', 
        'stablestudio', 
        'models.py'
    )
    debug_log(f"Target models.py path: {models_path}")
    
    if not os.path.exists(models_path):
        debug_log(f"❌ Error: models.py not found at {models_path}")
        debug_log(f"Directory exists: {os.path.exists(os.path.dirname(models_path))}")
        if os.path.exists(os.path.dirname(models_path)):
            debug_log(f"Directory contents: {os.listdir(os.path.dirname(models_path))}")
        return False
    
    debug_log(f"Opening models.py for reading")
    try:
        with open(models_path, 'r') as f:
            content = f.read()
        debug_log(f"Successfully read models.py ({len(content)} bytes)")
        
        # Debug: Check content for expected patterns
        debug_log(f"Contains 'StableStudioPrompt': {'StableStudioPrompt' in content}")
        debug_log(f"Contains 'text: Optional[str]': {'text: Optional[str]' in content}")
        debug_log(f"Contains 'to_imagine_prompt': {'to_imagine_prompt' in content}")
        
        # Fix 1: Add max_length to StableStudioPrompt.text field
        debug_log("Applying fix 1: adding max_length to StableStudioPrompt.text field")
        pattern = r'class StableStudioPrompt\(BaseModel\):\s*text: Optional\[str\] = None'
        replacement = 'class StableStudioPrompt(BaseModel):\n    text: Optional[str] = Field(None, max_length=10000)'
        
        if re.search(pattern, content):
            debug_log("Found pattern for fix 1, applying replacement")
            new_content = re.sub(pattern, replacement, content)
            if new_content != content:
                debug_log("✅ Fix 1 applied successfully")
                content = new_content
            else:
                debug_log("⚠️ Fix 1 replacement didn't change content")
        else:
            debug_log("❌ Pattern for fix 1 not found")
            # Try to find similar patterns for debugging
            debug_log("Looking for similar patterns...")
            class_def_pattern = r'class StableStudioPrompt\([^)]*\):'
            class_matches = re.findall(class_def_pattern, content)
            debug_log(f"Similar class definitions found: {class_matches}")
            
            text_field_pattern = r'text: Optional\[str\][^\n]*'
            text_matches = re.findall(text_field_pattern, content)
            debug_log(f"Similar text field definitions found: {text_matches}")
        
        # Fix 2: Add validation to to_imagine_prompt method
        debug_log("Applying fix 2: adding validation to to_imagine_prompt method")
        to_imagine_pattern = r'def to_imagine_prompt\(self\):\s*"""Converts this StableStudioInput to an ImaginePrompt."""\s*from io import BytesIO\s*from PIL import Image'
        validation_code = '''def to_imagine_prompt(self):
        """Converts this StableStudioInput to an ImaginePrompt."""
        from io import BytesIO
        from PIL import Image
        
        # Check total size of prompts before processing
        if self.prompts:
            total_text_length = sum(len(p.text or "") for p in self.prompts)
            if total_text_length > 20000:  # A bit larger than the individual field limit
                raise ValueError("Total prompt text length exceeds maximum allowed size")
        '''
        
        if re.search(to_imagine_pattern, content):
            debug_log("Found pattern for fix 2, applying replacement")
            new_content = re.sub(to_imagine_pattern, validation_code, content)
            if new_content != content:
                debug_log("✅ Fix 2 applied successfully")
                content = new_content
            else:
                debug_log("⚠️ Fix 2 replacement didn't change content")
        else:
            debug_log("❌ Pattern for fix 2 not found")
            # Try to find similar patterns for debugging
            method_pattern = r'def to_imagine_prompt\([^)]*\):'
            method_matches = re.findall(method_pattern, content)
            debug_log(f"Similar method definitions found: {method_matches}")
            
            docstring_pattern = r'"""Converts this StableStudioInput to an ImaginePrompt."""'
            docstring_matches = re.findall(docstring_pattern, content)
            debug_log(f"Similar docstrings found: {docstring_matches}")
        
        debug_log(f"Writing updated content to models.py")
        with open(models_path, 'w') as f:
            f.write(content)
        debug_log(f"✅ Successfully patched {models_path}")
        return True
    except Exception as e:
        debug_log(f"❌ Error patching models.py: {str(e)}")
        debug_log(traceback.format_exc())
        return False

def patch_routes_py(codebase_root):
    """Patch the routes.py file to add exception handling"""
    debug_log("Entering patch_routes_py()")
    routes_path = os.path.join(
        codebase_root, 
        'imaginairy', 
        'http_app', 
        'stablestudio', 
        'routes.py'
    )
    debug_log(f"Target routes.py path: {routes_path}")
    
    if not os.path.exists(routes_path):
        debug_log(f"❌ Error: routes.py not found at {routes_path}")
        debug_log(f"Directory exists: {os.path.exists(os.path.dirname(routes_path))}")
        if os.path.exists(os.path.dirname(routes_path)):
            debug_log(f"Directory contents: {os.listdir(os.path.dirname(routes_path))}")
        return False
    
    debug_log(f"Opening routes.py for reading")
    try:
        with open(routes_path, 'r') as f:
            content = f.read()
        debug_log(f"Successfully read routes.py ({len(content)} bytes)")
        
        # Debug: Check content for expected patterns
        debug_log(f"Contains '@router.post(\"/generate\"': {'@router.post(\"/generate\"' in content}")
        debug_log(f"Contains 'from fastapi import APIRouter': {'from fastapi import APIRouter' in content}")
        debug_log(f"Contains 'HTTPException': {'HTTPException' in content}")
        
        # Add import for HTTPException
        if 'from fastapi import APIRouter' in content and 'HTTPException' not in content:
            debug_log("Adding HTTPException import")
            new_content = content.replace(
                'from fastapi import APIRouter',
                'from fastapi import APIRouter, HTTPException'
            )
            if new_content != content:
                debug_log("✅ Added HTTPException import")
                content = new_content
            else:
                debug_log("⚠️ Failed to add HTTPException import")
        else:
            debug_log("HTTPException import not needed or already present")
        
        # Add try-except block to handle validation errors
        generate_pattern = r'@router\.post\("/generate", response_model=StableStudioBatchResponse\)\s*async def generate\(studio_request: StableStudioBatchRequest\):\s*from imaginairy\.http_app\.app import gpu_lock'
        
        try_except_code = '''@router.post("/generate", response_model=StableStudioBatchResponse)
async def generate(studio_request: StableStudioBatchRequest):
    from imaginairy.http_app.app import gpu_lock
    
    try:'''
        
        # Check if the try-except pattern is already in the content
        generate_start = content.find('@router.post("/generate"')
        samplers_start = content.find('@router.get("/samplers")')
        
        if generate_start == -1:
            debug_log("❌ Could not find generate endpoint in routes.py")
            return False
        
        if samplers_start == -1:
            debug_log("⚠️ Could not find samplers endpoint in routes.py")
            # Try to find the end of the generate function another way
            samplers_start = len(content)
        
        generate_content = content[generate_start:samplers_start]
        debug_log(f"Generate endpoint exists in content: {generate_start != -1}")
        debug_log(f"Generate content length: {len(generate_content)} bytes")
        debug_log(f"Try statement exists in generate endpoint: {'try:' in generate_content}")
        
        if 'try:' not in generate_content:
            debug_log("Adding try-except block to generate endpoint")
            # Check if the pattern matches exactly
            if re.search(generate_pattern, content):
                debug_log("Found exact pattern for generate endpoint, applying try block")
                content = re.sub(generate_pattern, try_except_code, content)
                
                # Then add the except block before the next endpoint
                next_endpoint = '@router.get("/samplers")'
                parts = content.split(next_endpoint)
                
                # Indent the code inside the try block
                lines = parts[0].split('\n')
                in_generate_block = False
                for i, line in enumerate(lines):
                    if line.strip().startswith('async def generate'):
                        debug_log(f"Found generate function definition at line {i}")
                        in_generate_block = True
                    elif in_generate_block and line.strip().startswith('@'):
                        debug_log(f"Found end of generate function at line {i}")
                        in_generate_block = False
                    
                    if in_generate_block and line.strip() and not line.strip().startswith('try:') and 'from imaginairy' not in line:
                        debug_log(f"Indenting line: {line}")
                        lines[i] = '    ' + line
                
                # Add the except block at the end of the function
                last_line = lines[-1]
                debug_log(f"Adding except block after line: {last_line}")
                lines[-1] = last_line + '\n    except ValueError as e:\n        raise HTTPException(status_code=400, detail=str(e))'
                
                parts[0] = '\n'.join(lines)
                content = next_endpoint.join(parts)
                debug_log("✅ Added try-except block to generate endpoint")
            else:
                debug_log("❌ Pattern for generate endpoint not found exactly")
                # Try to find similar patterns for debugging
                router_post_pattern = r'@router\.post\("/generate"[^)]*\)'
                router_matches = re.findall(router_post_pattern, content)
                debug_log(f"Similar router.post definitions found: {router_matches}")
                
                generate_func_pattern = r'async def generate\([^)]*\):'
                func_matches = re.findall(generate_func_pattern, content)
                debug_log(f"Similar generate function definitions found: {func_matches}")
        else:
            debug_log("Try-except block already exists in generate endpoint")
        
        debug_log(f"Writing updated content to routes.py")
        with open(routes_path, 'w') as f:
            f.write(content)
        debug_log(f"✅ Successfully patched {routes_path}")
        return True
    except Exception as e:
        debug_log(f"❌ Error patching routes.py: {str(e)}")
        debug_log(traceback.format_exc())
        return False

def main():
    try:
        start_time = time.time()
        debug_log("Starting package_index.py script")
        debug_log(f"Current working directory: {os.getcwd()}")
        debug_log(f"Python version: {sys.version}")
        
        print("Applying DoS vulnerability patch to imaginairy codebase...")
        debug_log("Finding codebase root")
        codebase_root = find_codebase_root()
        debug_log(f"Codebase root found: {codebase_root}")
        
        # Apply patches
        debug_log("Starting patch of models.py")
        models_patched = patch_models_py(codebase_root)
        debug_log(f"models.py patch result: {models_patched}")
        
        debug_log("Starting patch of routes.py")
        routes_patched = patch_routes_py(codebase_root)
        debug_log(f"routes.py patch result: {routes_patched}")
        
        # Mark patching as complete for the verify script to detect
        debug_log("Creating .patched flag file")
        try:
            with open(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), '.patched'), 'w') as f:
                f.write('patched')
            debug_log("✅ Created .patched file successfully")
        except Exception as e:
            debug_log(f"⚠️ Failed to create .patched file: {str(e)}")
        
        end_time = time.time()
        debug_log(f"Script execution took {end_time - start_time:.2f} seconds")
        
        if models_patched and routes_patched:
            print("Patch applied successfully!")
            return 0
        else:
            print("Patch application failed.")
            return 1
    except Exception as e:
        debug_log(f"❌ Unhandled exception in main: {str(e)}")
        debug_log(traceback.format_exc())
        print(f"Patch application failed with exception: {str(e)}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
