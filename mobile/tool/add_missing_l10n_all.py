#!/usr/bin/env python3
"""
Add missing l10n keys to all ARB files (not just app_en.arb)
"""

import json
import os
import sys

# Missing keys to add (same as English)
missing_keys = {
    "chatSearchHint": "Search messages",
    "@chatSearchHint": {
        "description": "screens/chat_screen_new.dart: placeholder for search input field"
    },
    "chatBurnTimer": "{seconds}s",
    "@chatBurnTimer": {
        "description": "screens/chat_screen_new.dart: burn timer countdown on message",
        "placeholders": {
            "seconds": {"type": "int"}
        }
    },
    "chatBurnOff": "Burn off",
    "@chatBurnOff": {
        "description": "screens/chat_screen_new.dart: button to turn off burn timer"
    },
    "chatEditHint": "Edit message",
    "@chatEditHint": {
        "description": "screens/chat_screen_new.dart: hint text in edit message dialog"
    },
    "chatUnsendConfirm": "Unsend message?",
    "@chatUnsendConfirm": {
        "description": "screens/chat_screen_new.dart: confirmation dialog title for unsend"
    },
    "chatUnsendConfirmDesc": "This will remove the message for everyone in the chat.",
    "@chatUnsendConfirmDesc": {
        "description": "screens/chat_screen_new.dart: confirmation dialog description for unsend"
    },
    "dayMonday": "Monday",
    "@dayMonday": {
        "description": "screens/chat_screen_new.dart: weekday name for date separator"
    },
    "dayTuesday": "Tuesday",
    "@dayTuesday": {
        "description": "screens/chat_screen_new.dart: weekday name for date separator"
    },
    "dayWednesday": "Wednesday",
    "@dayWednesday": {
        "description": "screens/chat_screen_new.dart: weekday name for date separator"
    },
    "dayThursday": "Thursday",
    "@dayThursday": {
        "description": "screens/chat_screen_new.dart: weekday name for date separator"
    },
    "dayFriday": "Friday",
    "@dayFriday": {
        "description": "screens/chat_screen_new.dart: weekday name for date separator"
    },
    "daySaturday": "Saturday",
    "@daySaturday": {
        "description": "screens/chat_screen_new.dart: weekday name for date separator"
    },
    "daySunday": "Sunday",
    "@daySunday": {
        "description": "screens/chat_screen_new.dart: weekday name for date separator"
    },
}

# Locale files to update
locale_files = [
    "lib/l10n/app_ar.arb",
    "lib/l10n/app_de.arb",
    "lib/l10n/app_es.arb",
    "lib/l10n/app_fa.arb",
    "lib/l10n/app_fr.arb",
    "lib/l10n/app_id.arb",
    "lib/l10n/app_it.arb",
    "lib/l10n/app_pt.arb",
    "lib/l10n/app_ru.arb",
    "lib/l10n/app_tr.arb",
    "lib/l10n/app_uk.arb",
    "lib/l10n/app_vi.arb",
    "lib/l10n/app_zh.arb",
    "lib/l10n/app_zh_Hant.arb",
]

def add_keys_to_arb(filepath):
    """Add missing keys to an ARB file."""
    try:
        with open(filepath, 'r', encoding='utf-8-sig') as f:
            content = f.read()
    except Exception as e:
        print(f"Error reading {filepath}: {e}")
        return False
    
    lines = content.split('\n')
    
    # Find a good place to insert - after the last existing key
    # We'll insert before the last closing brace
    insert_index = -1
    for i in range(len(lines) - 1, -1, -1):
        if lines[i].strip() == '}':
            insert_index = i
            break
    
    if insert_index == -1:
        print(f"Could not find insertion point in {filepath}")
        return False
    
    # Build the new lines to insert
    new_lines = ['']
    for key, value in missing_keys.items():
        if key.startswith('@'):
            continue
        
        new_lines.append(f'  "{key}": "{value}",')
        meta_key = f"@{key}"
        if meta_key in missing_keys:
            meta = missing_keys[meta_key]
            new_lines.append(f'  "{meta_key}": {{')
            if 'description' in meta:
                new_lines.append(f'    "description": "{meta["description"]}",')
            if 'placeholders' in meta:
                new_lines.append('    "placeholders": {')
                for ph_key, ph_val in meta['placeholders'].items():
                    new_lines.append(f'      "{ph_key}": {{')
                    for pk, pv in ph_val.items():
                        new_lines.append(f'        "{pk}": "{pv}",')
                    new_lines.append('      },')
                new_lines.append('    }')
            new_lines.append('  },')
    new_lines.append('')
    
    # Insert the new lines
    result_lines = lines[:insert_index] + new_lines + lines[insert_index:]
    
    try:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write('\n'.join(result_lines))
        print(f"Updated {filepath}")
        return True
    except Exception as e:
        print(f"Error writing {filepath}: {e}")
        return False

def main():
    success_count = 0
    for filepath in locale_files:
        if os.path.exists(filepath):
            if add_keys_to_arb(filepath):
                success_count += 1
        else:
            print(f"File not found: {filepath}")
    
    print(f"\nUpdated {success_count} out of {len(locale_files)} locale files")

if __name__ == '__main__':
    main()