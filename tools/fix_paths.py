# tools/fix_paths.py
import os
import re
from pathlib import Path

def get_relative_path(from_dir, target_rel):
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
    patterns = [
        (r'(href=")(/[^"]+)(")', 3),
        (r'(src=")(/[^"]+)(")', 3),
        (r"(window\.location\.href\s*=\s*)('|\")(\/[^'\"]+)\2", 4),
        (r"(fetch\(['\"])(\/[^'\"]+)(['\"])", 3)
    ]
    
    fixed_count = 0
    modified_files = []

    for dirpath, _, filenames in os.walk(root_dir):
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
                
                for pattern, group_count in patterns:
                    def replacer(match):
                        nonlocal fixed_count
                        groups = match.groups()
                        
                        # Extract path based on group count
                        if group_count == 3:
                            prefix, path, suffix = groups
                            if not path.startswith('/'): return match.group(0)
                            file_dir = os.path.dirname(filepath)
                            new_path = get_relative_path(file_dir, path)
                            fixed_count += 1
                            return f'{prefix}{new_path}{suffix}'
                        
                        elif group_count == 4:
                            prefix, quote_char, path, _ = groups
                            if not path.startswith('/'): return match.group(0)
                            file_dir = os.path.dirname(filepath)
                            new_path = get_relative_path(file_dir, path)
                            fixed_count += 1
                            return f'{prefix}{quote_char}{new_path}{quote_char}'
                            
                        return match.group(0)

                    content = re.sub(pattern, replacer, content)

                if content != original_content:
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(content)
                    modified_files.append(filepath)
                    print(f"[MODIFIED] {filepath}")

            except Exception as e:
                print(f"[ERROR] {filepath}: {e}")

    print(f"\n✅ Total Fixes Applied: {fixed_count}")
    return len(modified_files) > 0

if __name__ == "__main__":
    has_changes = process_files('.')
    # Signal exit code or output for CI
    if has_changes:
        sys.exit(0) # Success, changes made
    else:
        sys.exit(0) # Success, no changes needed
