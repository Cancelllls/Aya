#!/usr/bin/env python3
"""Bump the patch version in lib/version.dart and pubspec.yaml.

Usage:
  python3 tools/bump_version.py          # bump and print old→new
  python3 tools/bump_version.py --dry    # print what would happen

Bumps patch (1.1.0→1.1.1). Rolls over at 9:
  1.1.9 → 1.2.0
  1.9.9 → 2.0.0
  1.0.9 → 1.1.0

Version code formula: major*10000 + minor*100 + patch
  v1.1.0 → 10100  v2.0.0 → 20000
"""
import argparse, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VERSION_FILE = ROOT / "lib" / "version.dart"
PUBSPEC_FILE = ROOT / "pubspec.yaml"

DART_PATTERN = re.compile(
    r"^(const appVersion = ')(\d+)\.(\d+)\.(\d+)(';.*)$", re.MULTILINE
)
PUBSPEC_PATTERN = re.compile(r"^(version:\s*)(\d+\.\d+\.\d+)\+(\d+)(.*)$", re.MULTILINE)


def bump(version_str: str) -> tuple[int, int, int]:
    """Return (major, minor, patch) for the NEXT version."""
    m = re.match(r"^(\d+)\.(\d+)\.(\d+)$", version_str)
    if not m:
        raise ValueError(f"Not a valid semver: {version_str}")
    major, minor, patch = int(m[1]), int(m[2]), int(m[3])
    patch += 1
    if patch > 9:
        patch = 0
        minor += 1
    if minor > 9:
        minor = 0
        major += 1
    return major, minor, patch


def version_code(major: int, minor: int, patch: int) -> int:
    return major * 10000 + minor * 100 + patch


def fmt_ver(major: int, minor: int, patch: int) -> str:
    return f"{major}.{minor}.{patch}"


def main():
    parser = argparse.ArgumentParser(description="Bump Aya patch version")
    parser.add_argument("--dry", action="store_true", help="Print only, don't write")
    args = parser.parse_args()

    # 1. Read current version from version.dart
    dart_content = VERSION_FILE.read_text()
    dm = DART_PATTERN.search(dart_content)
    if not dm:
        sys.exit(f"ERROR: could not find version pattern in {VERSION_FILE}")

    old_ver = f"{dm[2]}.{dm[3]}.{dm[4]}"
    major, minor, patch = bump(old_ver)
    new_ver = fmt_ver(major, minor, patch)
    new_code = version_code(major, minor, patch)

    if args.dry:
        print(f"DRY RUN: {old_ver} → {new_ver}  (version code: {new_code})")
        print(f"  {VERSION_FILE.name}: {dm[0].strip()} → const appVersion = '{new_ver}';")
        return

    # 2. Write version.dart
    old_line = dm[0]
    new_line = f"{dm[1]}{new_ver}{dm[5]}"
    VERSION_FILE.write_text(dart_content.replace(old_line, new_line, 1))

    # 3. Write pubspec.yaml (sync version code for F-Droid UpdateCheckData)
    pub_content = PUBSPEC_FILE.read_text()
    pm = PUBSPEC_PATTERN.search(pub_content)
    if pm:
        new_pub_line = f"{pm[1]}{new_ver}+{new_code}{pm[4]}"
        PUBSPEC_FILE.write_text(pub_content.replace(pm[0], new_pub_line, 1))

    # Machine-parseable output for CI
    print(f"{old_ver} {new_ver}")


if __name__ == "__main__":
    main()
