import re
import subprocess

# Run dart analyze and get output
result = subprocess.run(['dart', 'analyze'], capture_output=True, text=True)
output = result.stdout + result.stderr

# Regex to find errors
pattern = r"error - (.+):(\d+):\d+ - (Invalid constant value|The values in a const list literal must be constants)"
errors = re.findall(pattern, output)

files = {}
for file, line, err_type in errors:
    line = int(line) - 1 # 0-indexed
    if file not in files:
        with open(file, 'r') as f:
            files[file] = f.readlines()
    
    # Strip const from this line
    line_content = files[file][line]
    line_content = re.sub(r'\bconst\s+', '', line_content)
    files[file][line] = line_content

for file, lines in files.items():
    with open(file, 'w') as f:
        f.writelines(lines)

print(f"Fixed {len(errors)} constant errors")
