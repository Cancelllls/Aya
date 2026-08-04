#!/usr/bin/env python3
"""Bump the patch version in lib/version.dart and return old/new versions.

Usage:
  python3 tools/bump_version.py          # bump and print old→new
  python3 tools/bump_version.py --dry    # print what would happen

Bumps patch (1.1.0→1.1.1). Rolls over at 9:
  1.1.9 → 1.2.0
  1.9.9 → 2.0.0
  1.0.9 → 1.1.0
"""
import argparse, re, sys
from pathlib import Path

VERSION_FILE = Path(__file__).resolve().parent.parent / "lib" / "version.dart"
PATTERN = re.compile(r"^(const appVersion = ')(\d+)\.(\d+)\.(\d+)(';.*)$", re.MULTILINE)


def bump(version_str: str) -> tuple[str, str]:
    """Return (old, new) version strings."""
    m = re.match(r"^(\d+)\.(\d+)\.(\d+)$", version_str)
    if not m:
        raise ValueError(f"Not a valid semver: {version_str}")
    major, minor, patch = int(m[1]), int(m[2]), int(m[3])
    old = f"{major}.{minor}.{patch}"
    patch += 1
    if patch > 9:
        patch = 0
        minor += 1
    if minor > 9:
        minor = 0
        major += 1
    new = f"{major}.{minor}.{patch}"
    return old, new


def main():
    parser = argparse.ArgumentParser(description="Bump Aya patch version")
    parser.add_argument("--dry", action="store_true", help="Print only, don't write")
    args = parser.parse_args()

    content = VERSION_FILE.read_text()
    m = PATTERN.search(content)
    if not m:
        sys.exit(f"ERROR: could not find version pattern in {VERSION_FILE}")

    old_full = f"{m[1]}{m[2]}.{m[3]}.{m[4]}{m[5]}"
    old_ver = f"{m[2]}.{m[3]}.{m[4]}"
    old_str, new_str = bump(old_ver)

    new_line = f"{m[1]}{new_str}{m[5]}"
    new_content = content.replace(old_full, new_line, 1)

    if args.dry:
        print(f"DRY RUN: {old_str} → {new_str}")
        print(f"  Would change: {old_full.strip()} → {new_line.strip()}")
        return

    VERSION_FILE.write_text(new_content)
    print(f"{old_str} {new_str}")  # machine-parseable output for CI


if __name__ == "__main__":
    main()
