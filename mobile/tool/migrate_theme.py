#!/usr/bin/env python3
"""
Theme migration script: HaloColors/HaloType -> UmbraTheme/UmbraTypography
"""

import re
import sys
from pathlib import Path

# Color mappings - using regex with word boundaries
COLOR_MAP = [
    (r'\bHaloColors\.ink\b', 'colors.ink'),
    (r'\bHaloColors\.surface\b', 'colors.surface'),
    (r'\bHaloColors\.surface2\b', 'colors.surfaceElevated'),
    (r'\bHaloColors\.surface3\b', 'colors.surfaceHover'),
    (r'\bHaloColors\.line\b', 'colors.separator'),
    (r'\bHaloColors\.line2\b', 'colors.separatorStrong'),
    (r'\bHaloColors\.text\b', 'colors.textPrimary'),
    (r'\bHaloColors\.text2\b', 'colors.textSecondary'),
    (r'\bHaloColors\.text3\b', 'colors.textTertiary'),
    (r'\bHaloColors\.warm\b', 'colors.textSecondary'),
    (r'\bHaloColors\.amber\b', 'colors.accent'),
    (r'\bHaloColors\.amberDeep\b', 'colors.accentHover'),
    (r'\bHaloColors\.amberSoft\b', 'colors.accentSoft'),
    (r'\bHaloColors\.green\b', 'colors.success'),
    (r'\bHaloColors\.greenSoft\b', 'colors.successSoft'),
    (r'\bHaloColors\.violet\b', 'colors.accent'),
    (r'\bHaloColors\.rose\b', 'colors.error'),
    (r'\bHaloColors\.onAmber\b', 'colors.accentOn'),
    (r'\bHaloColors\.bubbleIn\b', 'colors.bubbleIncoming'),
    (r'\bHaloColors\.amberBright\b', 'colors.accent'),
    (r'\bHaloColors\.amberBrightDeep\b', 'colors.accentHover'),
    (r'\bHaloColors\.amberInk\b', 'colors.ink'),
    (r'\bHaloColors\.qrPaper\b', 'colors.paper'),
    (r'\bHaloColors\.qrInk\b', 'colors.ink'),
    (r'\bHaloColors\.qrAmber\b', 'colors.accent'),
    (r'\bHaloColors\.qrViolet\b', 'colors.accent'),
    (r'\bHaloColors\.isLight\b', 'themeController.isLight'),
]

# Font family mappings
FONT_FAMILY_MAP = [
    (r'\bHaloType\.serifFamily\b', 'UmbraTypography.fontSerif'),
    (r'\bHaloType\.sansFamily\b', 'UmbraTypography.fontSans'),
    (r'\bHaloType\.monoFamily\b', 'UmbraTypography.fontMono'),
]

# Spacing mappings
SPACING_MAP = [
    (r'\bspace1\b', 'UmbraSpacing.space1'),
    (r'\bspace2\b', 'UmbraSpacing.space2'),
    (r'\bspace3\b', 'UmbraSpacing.space3'),
    (r'\bspace4\b', 'UmbraSpacing.space4'),
    (r'\bspace5\b', 'UmbraSpacing.space5'),
    (r'\bspace6\b', 'UmbraSpacing.space6'),
    (r'\bspace8\b', 'UmbraSpacing.space8'),
    (r'\bspace10\b', 'UmbraSpacing.space10'),
    (r'\bspace12\b', 'UmbraSpacing.space12'),
    (r'\bspace16\b', 'UmbraSpacing.space16'),
    (r'\bspace20\b', 'UmbraSpacing.space20'),
    (r'\bspace24\b', 'UmbraSpacing.space24'),
]

# Radius mappings - map common radius values to UmbraRadius tokens
RADIUS_MAP = [
    (r'\bBorderRadius\.circular\(4\)', 'BorderRadius.circular(UmbraRadius.sm)'),
    (r'\bBorderRadius\.circular\(8\)', 'BorderRadius.circular(UmbraRadius.md)'),
    (r'\bBorderRadius\.circular\(12\)', 'BorderRadius.circular(UmbraRadius.lg)'),
    (r'\bBorderRadius\.circular\(16\)', 'BorderRadius.circular(UmbraRadius.xl)'),
    (r'\bBorderRadius\.circular\(20\)', 'BorderRadius.circular(UmbraRadius.radius2xl)'),
    (r'\bBorderRadius\.circular\(24\)', 'BorderRadius.circular(UmbraRadius.radius3xl)'),
    (r'\bBorderRadius\.circular\(28\)', 'BorderRadius.circular(UmbraRadius.radius3xl)'),
    (r'\bRadius\.circular\(4\)', 'BorderRadius.circular(UmbraRadius.sm)'),
    (r'\bRadius\.circular\(8\)', 'BorderRadius.circular(UmbraRadius.md)'),
    (r'\bRadius\.circular\(12\)', 'BorderRadius.circular(UmbraRadius.lg)'),
    (r'\bRadius\.circular\(16\)', 'BorderRadius.circular(UmbraRadius.xl)'),
    (r'\bRadius\.circular\(20\)', 'BorderRadius.circular(UmbraRadius.radius2xl)'),
    (r'\bRadius\.circular\(24\)', 'BorderRadius.circular(UmbraRadius.radius3xl)'),
    (r'\bRadius\.circular\(28\)', 'BorderRadius.circular(UmbraRadius.radius3xl)'),
]

# Motion mappings
MOTION_MAP = [
    (r'\bDuration\(milliseconds: 50\)', 'UmbraMotion.durationFast'),
    (r'\bDuration\(milliseconds: 100\)', 'UmbraMotion.durationFast'),
    (r'\bDuration\(milliseconds: 150\)', 'UmbraMotion.durationNormal'),
    (r'\bDuration\(milliseconds: 200\)', 'UmbraMotion.durationNormal'),
    (r'\bDuration\(milliseconds: 240\)', 'UmbraMotion.durationNormal'),
    (r'\bDuration\(milliseconds: 250\)', 'UmbraMotion.durationNormal'),
    (r'\bDuration\(milliseconds: 300\)', 'UmbraMotion.durationSlow'),
    (r'\bDuration\(milliseconds: 400\)', 'UmbraMotion.durationSlow'),
    (r'\bDuration\(milliseconds: 500\)', 'UmbraMotion.durationSlower'),
    (r'\bDuration\(milliseconds: 600\)', 'UmbraMotion.eclipseWipeDuration'),
    (r'\bCurves\.easeOutCubic\b', 'UmbraMotion.easeOut'),
    (r'\bCurves\.easeInOutCubic\b', 'UmbraMotion.easeInOut'),
    (r'\bCurves\.easeOut\b', 'UmbraMotion.easeOut'),
    (r'\bCurves\.easeIn\b', 'UmbraMotion.easeSharp'),
]

# Import replacements
OLD_THEME_IMPORT = "import '../theme.dart';"
NEW_THEME_IMPORT = "import '../theme/theme.dart';"

def migrate_file(filepath: Path) -> bool:
    """Migrate a single Dart file from old theme to new theme."""
    content = filepath.read_text(encoding='utf-8')
    original = content
    
    # Replace theme import
    content = content.replace(OLD_THEME_IMPORT, NEW_THEME_IMPORT)
    
    # Replace color references using regex
    for pattern, replacement in COLOR_MAP:
        content = re.sub(pattern, replacement, content)
    
    # Replace font family references
    for pattern, replacement in FONT_FAMILY_MAP:
        content = re.sub(pattern, replacement, content)
    
    # Replace spacing references
    for pattern, replacement in SPACING_MAP:
        content = re.sub(pattern, replacement, content)
    
    # Replace radius references
    for pattern, replacement in RADIUS_MAP:
        content = re.sub(pattern, replacement, content)
    
    # Replace motion references
    for pattern, replacement in MOTION_MAP:
        content = re.sub(pattern, replacement, content)
    
    # Handle HaloType.serif, HaloType.sans, HaloType.mono calls
    content = migrate_halo_type_calls(content)
    
    # Add colors variable to all build methods
    content = add_colors_variable(content)
    
    # Add themeController variable if HaloColors.isLight was used
    if 'HaloColors.isLight' in original and 'final themeController = UmbraTheme.of(context);' not in content:
        content = add_theme_controller_variable(content)
    
    if content != original:
        filepath.write_text(content, encoding='utf-8')
        return True
    return False

def migrate_halo_type_calls(content: str) -> str:
    """Migrate HaloType.serif/sans/mono calls to TextStyle with UmbraTypography."""
    
    # Pattern for HaloType.serif(...)
    def replace_serif(match):
        args = match.group(1)
        # Parse named arguments
        size = extract_arg(args, 'size', '26')
        weight = extract_arg(args, 'weight', 'FontWeight.w400')
        color = extract_arg(args, 'color', None)
        italic = extract_arg(args, 'italic', 'false')
        height = extract_arg(args, 'height', '1.05')
        letter = extract_arg(args, 'letter', '-0.015')
        
        color_str = f', color: {color}' if color else ''
        italic_str = 'FontStyle.italic' if italic == 'true' else 'FontStyle.normal'
        
        return f'TextStyle(fontFamily: UmbraTypography.fontSerif, fontSize: {size}, fontWeight: {weight}{color_str}, fontStyle: {italic_str}, height: {height}, letterSpacing: {letter})'
    
    def replace_sans(match):
        args = match.group(1)
        size = extract_arg(args, 'size', '13')
        weight = extract_arg(args, 'weight', 'FontWeight.w400')
        color = extract_arg(args, 'color', None)
        height = extract_arg(args, 'height', '1.5')
        letter = extract_arg(args, 'letter', '0')
        
        color_str = f', color: {color}' if color else ''
        
        return f'TextStyle(fontFamily: UmbraTypography.fontSans, fontSize: {size}, fontWeight: {weight}{color_str}, height: {height}, letterSpacing: {letter})'
    
    def replace_mono(match):
        args = match.group(1)
        size = extract_arg(args, 'size', '11')
        weight = extract_arg(args, 'weight', 'FontWeight.w500')
        color = extract_arg(args, 'color', None)
        letter = extract_arg(args, 'letter', '0.12')
        
        color_str = f', color: {color}' if color else ''
        
        return f'TextStyle(fontFamily: UmbraTypography.fontMono, fontSize: {size}, fontWeight: {weight}{color_str}, letterSpacing: {letter})'
    
    content = re.sub(r'HaloType\.serif\(([^)]*)\)', replace_serif, content)
    content = re.sub(r'HaloType\.sans\(([^)]*)\)', replace_sans, content)
    content = re.sub(r'HaloType\.mono\(([^)]*)\)', replace_mono, content)
    
    return content

def extract_arg(args_str: str, name: str, default: str) -> str:
    """Extract a named argument from a function call string."""
    pattern = rf'{name}:\s*([^,)]+)'
    match = re.search(pattern, args_str)
    if match:
        return match.group(1).strip()
    return default

def add_colors_variable(content: str) -> str:
    """Add 'final colors = UmbraTheme.colorsOf(context);' after each build method starts."""
    # Find all build methods and add after each opening brace
    pattern = r'(@override\s+)?Widget build\(BuildContext context\)\s*\{'
    
    def replace_build(match):
        indent = '  '
        addition = f'\n{indent}final colors = UmbraTheme.colorsOf(context);\n'
        return match.group(0) + addition
    
    content = re.sub(pattern, replace_build, content)
    return content

def add_theme_controller_variable(content: str) -> str:
    """Add 'final themeController = UmbraTheme.of(context);' after each build method starts."""
    pattern = r'(@override\s+)?Widget build\(BuildContext context\)\s*\{'
    
    def replace_build(match):
        indent = '  '
        addition = f'\n{indent}final themeController = UmbraTheme.of(context);\n'
        return match.group(0) + addition
    
    content = re.sub(pattern, replace_build, content)
    return content

def main():
    if len(sys.argv) < 2:
        print("Usage: python migrate_theme.py <file_or_directory>")
        sys.exit(1)
    
    target = Path(sys.argv[1])
    files_migrated = 0
    
    if target.is_file():
        if migrate_file(target):
            print(f"Migrated: {target}")
            files_migrated += 1
    elif target.is_dir():
        for filepath in target.rglob('*.dart'):
            try:
                if migrate_file(filepath):
                    print(f"Migrated: {filepath}")
                    files_migrated += 1
            except UnicodeDecodeError:
                print(f"Skipped (encoding issue): {filepath}")
    
    print(f"\nTotal files migrated: {files_migrated}")

if __name__ == '__main__':
    main()