# =========================================
# Project: Pahatid System Project
# File: tools/fix_paths.py
# Description: Auto-fixes hardcoded absolute paths (/) to relative paths AND injects sidebar.js
# Author: AI Assistant
# Date: 2026-09-29
# Version: 1.3.0 (Added Sidebar JS Injection Logic)
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
    
    # Pattern to detect if a page likely needs the sidebar script
    # Looks for standard sidebar IDs or classes used in our templates
    SIDEBAR_DETECTION_PATTERN = r'(id=["\']app-sidebar["\']|class=["\'][^"\']*sidebar[^"\']*["\'])'
    
    # Target script to inject
    TARGET_SCRIPT_SRC = "assets/js/sidebar.js"
    SCRIPT_TAG_TEMPLATE = '<script src="{}"></script>'

    # Define specific patterns to replace for general links
    replacements = [
        # href="/..." -> href="relative/..."
        (r'href="(/[^"]+)"', 1, 'href="{}"', None),
        # src="/..." -> src="relative/..."
        (r'src="(/[^"]+)"', 1, 'src="{}"', None),
        # window.location.href = '/...'
        (r"(window\.location\.href\s*=\s*)['\"](/[^'\"]+)['\"]", 2, "{}'{}'", None),
        # fetch('/...')
        (r"(fetch\(['\"])(/[^'\"]+)(['\"])", 2, "{}{}{}", None)
    ]

    for dirpath, _, filenames in os.walk(root_dir):
        # Skip hidden dirs and node_modules
        if '.git' in dirpath or 'node_modules' in dirpath or '.github' in dirpath or 'tools' in dirpath:
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
                has_modifications = False

                # --- STEP 1: Fix Absolute Paths to Relative ---
                for pattern, path_group_idx, template, _ in replacements:
                    
                    def make_replacer(p_group_idx, tmpl):
                        def replacer(match):
                            nonlocal has_modifications
                            # Get the matched path
                            path_val = match.group(p_group_idx)
                            
                            # Only process if it starts with /
                            if not path_val.startswith('/'):
                                return match.group(0)
                            
                            # Calculate new relative path
                            new_path = get_relative_path(file_dir, path_val)
                            
                            # Mark that we changed something
                            has_modifications = True
                            
                            # Format the string using the template
                            if p_group_idx == 1: # href/src case
                                prefix = match.group(0)[:match.start(1)-match.start(0)]
                                suffix = match.group(0)[match.end(1)-match.start(0):]
                                return f'{prefix}{new_path}{suffix}'
                            elif p_group_idx == 2: # window/fetch case
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

                # --- STEP 2: Inject sidebar.js if needed ---
                # Check if this file contains a sidebar element
                if re.search(SIDEBAR_DETECTION_PATTERN, content, re.IGNORECASE):
                    
                    # Check if sidebar.js is ALREADY included
                    # We look for the filename specifically to avoid partial matches
                    if TARGET_SCRIPT_SRC not in content:
                        
                        # Calculate correct relative path for the script
                        # Note: We assume assets folder is at project root level relative to where we calculate
                        # But since we are injecting into HTML, we need the path FROM THIS FILE TO THE ASSET
                        
                        # Construct absolute path of asset from root for calculation
                        # Actually, simpler: just use get_relative_path logic on the target string
                        final_script_path = get_relative_path(file_dir, '/' + TARGET_SCRIPT_SRC)
                        
                        new_script_tag = SCRIPT_TAG_TEMPLATE.format(final_script_path)
                        
                        # Find the last </body> tag to insert before it
                        body_close_match = list(re.finditer(r'</body>', content, re.IGNORECASE))
                        
                        if body_close_match:
                            last_body_close = body_close_match[-1]
                            insert_pos = last_body_close.start()
                            
                            # Insert the script tag
                            content = content[:insert_pos] + '\n    ' + new_script_tag + '\n' + content[insert_pos:]
                            has_modifications = True
                            print(f"[INFO] Injected {TARGET_SCRIPT_SRC} into {filepath}")
                        else:
                            print(f"[WARN] Could not find </body> in {filepath} to inject script.")

                # --- SAVE CHANGES IF ANY ---
                if has_modifications:
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(content)
                    modified_files.append(filepath)
                    print(f"[MODIFIED] {filepath}")
                    fixed_count += 1 

            except Exception as e:
                print(f"[ERROR] {filepath}: {e}")

    print(f"\n✅ Total Files Modified: {len(modified_files)}")
    return len(modified_files) > 0

if __name__ == "__main__":
    has_changes = process_files('.')
    sys.exit(0)
