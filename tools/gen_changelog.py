#!/usr/bin/env python3
"""Generate release changelog from assets/changelog.json for the given version."""
import json, sys, os

version = sys.argv[1] if len(sys.argv) > 1 else ''
script_dir = os.path.dirname(os.path.abspath(__file__))
changelog_path = os.path.join(script_dir, '..', 'assets', 'changelog.json')

try:
    with open(changelog_path) as f:
        data = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    print('## Recent Changes')
    sys.exit(0)

for entry in data.get('versions', []):
    if entry['version'] != version:
        continue

    # English section
    print(f"## {entry['title']} (v{version})")
    print()
    for line in entry['changes']['en']:
        print(f"- {line}")
    print()

    # Arabic section
    print(f"---")
    print()
    print(f"## {entry['title']} (v{version})")
    print()
    for line in entry['changes']['ar']:
        print(f"- {line}")
    break
else:
    print(f'## Version {version}')
