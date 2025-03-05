#!/usr/bin/env python3
"""
Patch script for imaginairy DoS vulnerability in StableStudio generate endpoint.
This script automatically applies fixes to models.py and routes.py
"""

import os
import re
import sys

def find_codebase_root():
    """Find the imaginairy codebase root directory"""
    # Start from the current directory and go up until we find the codebase directory
    current_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Go up to bounty_0 directory, then to bounties, then to imaginairy root
    bounty_dir = os.path.dirname(current_dir)  # bounty_0
    bounties_dir = os.path.dirname(bounty_dir)  # bounties
    repo_root = os.path.dirname(bounties_dir)  # imaginairy root
    
    codebase_dir = os.path.join(repo_root, 'codebase')
    if not os.path.exists(codebase_dir):
        print(f"Error: Codebase directory not found at {codebase_dir}")
        sys.exit(1)
    
    return codebase_dir

def patch_models_py(codebase_root):
    """Patch the models.py file to add input validation"""
    models_path = os.path.join(
        codebase_root, 
        'imaginairy', 
        'http_app', 
        'stablestudio', 
        'models.py'
    )
    
    if not os.path.exists(models_path):
        print(f"Error: models.py not found at {models_path}")
        return False
    
    with open(models_path, 'r') as f:
        content = f.read()
    
    # Fix 1: Add max_length to StableStudioPrompt.text field
    content = re.sub(
        r'class StableStudioPrompt\(BaseModel\):\s*text: Optional\[str\] = None',
        'class StableStudioPrompt(BaseModel):\n    text: Optional[str] = Field(None, max_length=10000)',
        content
    )
    
    # Fix 2: Add validation to to_imagine_prompt method
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
    
    content = re.sub(to_imagine_pattern, validation_code, content)
    
    with open(models_path, 'w') as f:
        f.write(content)
    
    print(f"Successfully patched {models_path}")
    return True

def patch_routes_py(codebase_root):
    """Patch the routes.py file to add exception handling"""
    routes_path = os.path.join(
        codebase_root, 
        'imaginairy', 
        'http_app', 
        'stablestudio', 
        'routes.py'
    )
    
    if not os.path.exists(routes_path):
        print(f"Error: routes.py not found at {routes_path}")
        return False
    
    with open(routes_path, 'r') as f:
        content = f.read()
    
    # Add import for HTTPException
    if 'from fastapi import APIRouter' in content and 'HTTPException' not in content:
        content = content.replace(
            'from fastapi import APIRouter',
            'from fastapi import APIRouter, HTTPException'
        )
    
    # Add try-except block to handle validation errors
    generate_pattern = r'@router\.post\("/generate", response_model=StableStudioBatchResponse\)\s*async def generate\(studio_request: StableStudioBatchRequest\):\s*from imaginairy\.http_app\.app import gpu_lock'
    
    try_except_code = '''@router.post("/generate", response_model=StableStudioBatchResponse)
async def generate(studio_request: StableStudioBatchRequest):
    from imaginairy.http_app.app import gpu_lock
    
    try:'''
    
    # Check if the try-except pattern is already in the content
    if 'try:' not in content[content.find('@router.post("/generate"'):content.find('@router.get("/samplers")')]:
        # First, add the try block
        content = re.sub(generate_pattern, try_except_code, content)
        
        # Then add the except block before the next endpoint
        next_endpoint = '@router.get("/samplers")'
        parts = content.split(next_endpoint)
        
        # Indent the code inside the try block
        lines = parts[0].split('\n')
        in_generate_block = False
        for i, line in enumerate(lines):
            if line.strip().startswith('async def generate'):
                in_generate_block = True
            elif in_generate_block and line.strip().startswith('@'):
                in_generate_block = False
            
            if in_generate_block and line.strip() and not line.strip().startswith('try:') and 'from imaginairy' not in line:
                lines[i] = '    ' + line
        
        # Add the except block at the end of the function
        last_line = lines[-1]
        lines[-1] = last_line + '\n    except ValueError as e:\n        raise HTTPException(status_code=400, detail=str(e))'
        
        parts[0] = '\n'.join(lines)
        content = next_endpoint.join(parts)
    
    with open(routes_path, 'w') as f:
        f.write(content)
    
    print(f"Successfully patched {routes_path}")
    return True

def main():
    print("Applying DoS vulnerability patch to imaginairy codebase...")
    codebase_root = find_codebase_root()
    
    # Apply patches
    models_patched = patch_models_py(codebase_root)
    routes_patched = patch_routes_py(codebase_root)
    
    if models_patched and routes_patched:
        print("Patch applied successfully!")
        return 0
    else:
        print("Patch application failed.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
