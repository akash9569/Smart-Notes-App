import os
import glob
import re

files = glob.glob('lib/widgets/*.dart')

for filepath in files:
    if 'dashboard.dart' in filepath or 'profile_view.dart' in filepath:
        continue
        
    with open(filepath, 'r') as f:
        content = f.read()

    # Add imports if missing
    if 'import \'../app_theme.dart\';' not in content:
        content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../app_theme.dart';")
    
    # Text colors
    content = re.sub(r'Colors\.white70', 'context.themeTextSecondary', content)
    content = re.sub(r'Colors\.white\.withOpacity\((.*?)\)', r'context.themeTextPrimary.withValues(alpha: \1)', content)
    content = re.sub(r'Colors\.white10', 'context.themeTextPrimary.withValues(alpha: 0.1)', content)
    content = re.sub(r'Colors\.white12', 'context.themeTextPrimary.withValues(alpha: 0.12)', content)
    content = re.sub(r'Colors\.white24', 'context.themeTextPrimary.withValues(alpha: 0.24)', content)
    content = re.sub(r'Colors\.white38', 'context.themeTextPrimary.withValues(alpha: 0.38)', content)
    content = re.sub(r'Colors\.white54', 'context.themeTextPrimary.withValues(alpha: 0.54)', content)
    content = re.sub(r'Colors\.white60', 'context.themeTextPrimary.withValues(alpha: 0.60)', content)
    content = re.sub(r'Colors\.white', 'context.themeTextPrimary', content)
    
    # Backgrounds
    content = re.sub(r'AppColors\.background', 'context.themeBackground', content)
    content = re.sub(r'AppColors\.cardBackground', 'context.themeCardBackground', content)
    content = re.sub(r'AppColors\.sidebarBackground', 'context.themeSidebarBackground', content)
    
    # Remove const from TextStyles if they contain context
    content = re.sub(r'const\s+TextStyle\(\s*color:\s*context\.theme', r'TextStyle(color: context.theme', content)
    content = re.sub(r'const\s+TextStyle\([^)]*context\.themeTextPrimary[^)]*\)', lambda m: m.group(0).replace('const ', ''), content)
    content = re.sub(r'const\s+TextStyle\([^)]*context\.themeTextSecondary[^)]*\)', lambda m: m.group(0).replace('const ', ''), content)
    
    # Premium decoration wrapper
    content = re.sub(r'AppTheme\.premiumDecoration\(\)', 'AppTheme.premiumDecoration(context: context)', content)
    content = re.sub(r'AppTheme\.premiumDecoration\((?!context)', 'AppTheme.premiumDecoration(context: context, ', content)

    with open(filepath, 'w') as f:
        f.write(content)

print("Theme replacements completed.")
