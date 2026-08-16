import re
import subprocess

# Run dart analyze and get output
result = subprocess.run(['dart', 'analyze'], capture_output=True, text=True)
output = result.stdout + result.stderr

# Regex to find errors
pattern = r"error - (.+):(\d+):\d+ - Invalid constant value"
errors = re.findall(pattern, output)

files = {}
for file, line in errors:
    line = int(line) - 1 # 0-indexed
    if file not in files:
        with open(file, 'r') as f:
            files[file] = f.readlines()
    
    # Strip const from this line
    files[file][line] = re.sub(r'\bconst\s+', '', files[file][line])

    # Sometimes const is on the previous line e.g. `const Padding(\n  padding: ...`
    # Let's also strip const from up to 3 lines above if they have const
    for i in range(max(0, line-3), line):
        files[file][i] = re.sub(r'\bconst\s+', '', files[file][i])

for file, lines in files.items():
    with open(file, 'w') as f:
        f.writelines(lines)

print(f"Fixed {len(errors)} constant errors")
