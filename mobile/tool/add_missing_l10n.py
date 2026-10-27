#!/usr/bin/env python3
"""
Add missing l10n keys to app_en.arb
"""

import json
import sys

# Read the existing ARB file
with open('lib/l10n/app_en.arb', 'r', encoding='utf-8-sig') as f:
    content = f.read()

# Parse as JSON (ARB is essentially JSON)
arb = json.loads(content)

# Missing keys to add
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

# Find a good place to insert - after chatYesterday
# We'll just add them at the end of the file, before the last closing brace
# Actually, ARB files don't care about order, but for readability let's insert after chatYesterday

# Convert back to JSON with pretty printing
# We'll insert the new keys in a specific location for readability

# Find the position of "chatYesterday" and insert after its metadata
lines = content.split('\n')
insert_index = -1
for i, line in enumerate(lines):
    if '"chatYesterday"' in line:
        # Find the closing brace of its metadata
        for j in range(i, len(lines)):
            if lines[j].strip() == '}':
                # Check if next line is also closing brace (for the description object)
                if j + 1 < len(lines) and lines[j + 1].strip() == '}':
                    insert_index = j + 1
                    break
        break

if insert_index == -1:
    print("Could not find chatYesterday, inserting at end")
    insert_index = len(lines) - 1

# Build the new lines to insert
new_lines = []
for key, value in missing_keys.items():
    if key.startswith('@'):
        continue  # Skip metadata for now, we'll add it with the main key
    
    # Add the key
    new_lines.append(f'  "{key}": "{value}",')
    # Add metadata
    meta_key = f"@{key}"
    if meta_key in missing_keys:
        meta = missing_keys[meta_key]
        new_lines.append(f'  "@{key}": {{')
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

# Insert the new lines
result_lines = lines[:insert_index] + [''] + new_lines + [''] + lines[insert_index:]

# Write back
with open('lib/l10n/app_en.arb', 'w', encoding='utf-8') as f:
    f.write('\n'.join(result_lines))

print(f"Added {len(missing_keys)//2} keys to app_en.arb")
print("Done!")