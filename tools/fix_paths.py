# =========================================
# Project: Pahatid System Project
# File: tools/fix_paths.py
# Description: Auto-fixes hardcoded absolute paths (/) to relative paths in HTML files.
# Author: AI Assistant
# Date: 2026-09-29
# Version: 1.2.0 (Fixed Regex & Imports)
# =========================================

import os
import re
import sys
from pathlib import Path

def get_relative_path(from_dir, target_rel):
    """Calculates relative path from source dir to target."""
    try:
        abs_from = Path(from_dir).resolve()
        # Strip leading slash to treat as relative to root
        clean_target = target_rel.lstrip('/')
        abs_target = Path(clean_target).resolve() 
        rel_path = os.path.relpath(abs_target, start=abs_from)
        return rel_path.replace("\\", "/")
    except Exception:
        return target_rel

def process_files(root_dir='.'):
    fixed_count = 0
    modified_files = []

    # Define specific patterns to replace
    # We use a list of tuples: (regex_pattern, group_index_for_path, prefix_template, suffix_template)
    # This is safer than complex backreferences
    
    replacements = [
        # href="/..." -> href="relative/..."
        (r'href="(/[^"]+)"', 1, 'href="{}"', None),
        # src="/..." -> src="relative/..."
        (r'src="(/[^"]+)"', 1, 'src="{}"', None),
        # window.location.href = '/...' or "...'"
        (r"(window\.location\.href\s*=\s*)['\"](/[^'\"]+)['\"]", 2, "{}'{}'", None),
        # fetch('/...')
        (r"(fetch\(['\"])(/[^'\"]+)(['\"])", 2, "{}{}{}", None)
    ]

    for dirpath, _, filenames in os.walk(root_dir):
        # Skip hidden dirs and node_modules
        if '.git' in dirpath or 'node_modules' in dirpath or '.github' in dirpath:
            continue
            
        for filename in filenames:
            if not filename.endswith('.html'):
                continue
                
            filepath = os.path.join(dirpath, filename)
            
            try:
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                original_content = content
                file_dir = os.path.dirname(filepath)

                # Apply each replacement rule
                for pattern, path_group_idx, template, _ in replacements:
                    
                    def make_replacer(p_group_idx, tmpl):
                        def replacer(match):
                            nonlocal fixed_count
                            # Get the matched path
                            path_val = match.group(p_group_idx)
                            
                            # Only process if it starts with /
                            if not path_val.startswith('/'):
                                return match.group(0)
                            
                            # Calculate new relative path
                            new_path = get_relative_path(file_dir, path_val)
                            
                            # Format the string using the template
                            # The template expects the full match structure reconstructed
                            # For simplicity, we reconstruct based on known parts
                            
                            if p_group_idx == 1: # href/src case
                                prefix = match.group(0)[:match.start(1)-match.start(0)]
                                suffix = match.group(0)[match.end(1)-match.start(0):]
                                return f'{prefix}{new_path}{suffix}'
                            elif p_group_idx == 2: # window/fetch case
                                # Groups are usually (prefix, path, suffix_quote) or similar
                                # Let's rebuild manually for safety
                                g1 = match.group(1)
                                g3 = match.group(3) if len(match.groups()) >= 3 else ""
                                
                                # Special handling for quotes in window.location.href
                                if "window.location.href" in g1:
                                    quote_char = "'" if "'" in match.group(0) else '"'
                                    return f"{g1}{quote_char}{new_path}{quote_char}"
                                else:
                                    # Fetch case: fetch('...')
                                    return f"{g1}{new_path}{g3}"
                            
                            return match.group(0)
                        return replacer

                    content = re.sub(pattern, make_replacer(path_group_idx, template), content)

                if content != original_content:
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(content)
                    modified_files.append(filepath)
                    print(f"[MODIFIED] {filepath}")
                    fixed_count += 1 # Count files modified, not individual links

            except Exception as e:
                print(f"[ERROR] {filepath}: {e}")

    print(f"\n✅ Total Files Modified: {len(modified_files)}")
    return len(modified_files) > 0

if __name__ == "__main__":
    has_changes = process_files('.')
    sys.exit(0)
