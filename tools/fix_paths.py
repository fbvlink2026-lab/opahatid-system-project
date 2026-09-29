# =========================================
# Project: Pahatid System Project
# File: tools/fix_paths.py
# Description: Automated Script to Fix Hardcoded Absolute Paths to Relative Paths
# Author: AI Assistant
# Date: 2026-09-29
# Version: 1.0.0
# Usage: Run this script locally using Python 3.x after cloning the repo.
#        python tools/fix_paths.py
# =========================================

import os
import re
from pathlib import Path

def get_relative_path(from_file_dir, target_path):
    """
    Calculates the relative path from a source directory to a target path.
    Handles cases where target might be in parent directories.
    """
    try:
        # Convert to absolute paths for accurate calculation
        abs_from = Path(from_file_dir).resolve()
        abs_target = Path(target_path).resolve()
        
        # Calculate relative path
        rel_path = os.path.relpath(abs_target, start=abs_from)
        
        # Normalize separators for web URLs (always use forward slashes)
        rel_path = rel_path.replace("\\", "/")
        
        # Ensure it starts with ./ or ../ correctly if needed, 
        # but standard HTML href/src usually works fine with just the relative part.
        return rel_path
    except Exception as e:
        print(f"Error calculating path for {target_path}: {e}")
        return target_path

def process_html_files(root_dir):
    """
    Scans all .html files and replaces absolute paths starting with '/' 
    with correct relative paths based on the file's location.
    """
    
    # Patterns to find:
    # 1. href="/..."
    # 2. src="/..."
    # 3. window.location.href = '/...'
    # 4. fetch('/...') or supabase calls if any hardcoded
    
    patterns = [
        r'href="(/[^"]+)"',
        r'src="(/[^"]+)"',
        r"window\.location\.href\s*=\s*'([^']+)'",
        r"window\.location\.href\s*=\s*\"([^\"]+)\"",
        r"fetch\(['\"](/[^'\"]+)['\"]"
    ]

    count_fixed = 0
    
    for dirpath, _, filenames in os.walk(root_dir):
        for filename in filenames:
            if not filename.endswith('.html'):
                continue
                
            filepath = os.path.join(dirpath, filename)
            
            # Skip if it's inside node_modules or .git (just in case)
            if '.git' in dirpath or 'node_modules' in dirpath:
                continue

            try:
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                original_content = content
                current_dir = dirpath

                # Helper function to replace matches
                def replace_match(match):
                    nonlocal count_fixed
                    full_match = match.group(0)
                    captured_path = match.group(1)
                    
                    # Only process if it starts with / (absolute root)
                    if not captured_path.startswith('/'):
                        return full_match
                    
                    # Ignore external URLs (http://, https://)
                    if captured_path.startswith('//'):
                        return full_match

                    # Construct the absolute target path from root
                    # Assuming root_dir is the base
                    target_abs = os.path.join(root_dir, captured_path.lstrip('/'))
                    
                    # Get relative path from current file's directory
                    rel_path = get_relative_path(current_dir, target_abs)
                    
                    # Reconstruct the tag/string with new relative path
                    # We need to preserve the quote style used in the original match
                    quote_char = '"' if '"' in full_match else "'"
                    
                    # Special handling for JS assignments like window.location.href = '/...'
                    if 'window.location.href' in full_match:
                         # Keep the assignment syntax intact
                         prefix = full_match.split(captured_path)[0]
                         suffix = full_match.split(captured_path)[-1]
                         new_string = f"{prefix}{quote_char}{rel_path}{quote_char}{suffix}"
                    else:
                         # Standard HTML attributes
                         attr_part = full_match.split('=')[0] # e.g., href or src
                         new_string = f'{attr_part}="{rel_path}"'
                         
                    count_fixed += 1
                    return new_string

                # Apply replacements for each pattern
                for pattern in patterns:
                    content = re.sub(pattern, replace_match, content)

                # Write back only if changed
                if content != original_content:
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(content)
                    print(f"[FIXED] {filepath}")
                else:
                    pass # print(f"[SKIP] {filepath} - No changes needed")

            except Exception as e:
                print(f"[ERROR] Processing {filepath}: {e}")

    print(f"\n✅ Done! Fixed {count_fixed} paths across the project.")
    print(" Please commit these changes to GitHub now.")

if __name__ == "__main__":
    # Determine root directory (parent of 'tools' folder)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    root_dir = os.path.dirname(script_dir)
    
    print(f"Scanning project root: {root_dir}")
    process_html_files(root_dir)
