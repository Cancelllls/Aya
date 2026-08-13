#!/usr/bin/env python3
"""Generate changelog for a release. Reads manual entries from
assets/changelog.json. Falls back to git commit log since last tag.

Usage:
  python3 tools/gen_changelog.py <version>     # CI: generate for release
  python3 tools/gen_changelog.py               # print from git log (dry run)
"""
import json, os, subprocess, sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CHANGELOG_PATH = os.path.join(SCRIPT_DIR, "..", "assets", "changelog.json")


def _git_log_since_tag():
    """Collect commit messages since the last git tag."""
    try:
        # Find the last tag
        last_tag = (
            subprocess.check_output(
                ["git", "describe", "--tags", "--abbrev=0"],
                stderr=subprocess.DEVNULL,
            )
            .decode()
            .strip()
        )
        log = subprocess.check_output(
            ["git", "log", f"{last_tag}..HEAD", "--pretty=format:%s"],
            stderr=subprocess.DEVNULL,
        ).decode().strip()
    except subprocess.CalledProcessError:
        # No tags yet — use all commits
        log = (
            subprocess.check_output(
                ["git", "log", "--pretty=format:%s"],
                stderr=subprocess.DEVNULL,
            )
            .decode()
            .strip()
        )
    return [line.strip() for line in log.split("\n") if line.strip()]


def _classify_commits(messages: list[str]) -> tuple[list[str], list[str], list[str]]:
    """Split into feat, fix, and other buckets."""
    feat, fix, other = [], [], []
    for msg in messages:
        # Skip merge commits and CI commits
        if msg.startswith("Merge ") or msg.startswith("[skip ci]"):
            continue
        lower = msg.lower()
        if lower.startswith("feat") or lower.startswith("add"):
            feat.append(msg)
        elif lower.startswith("fix") or lower.startswith("bug"):
            fix.append(msg)
        elif lower.startswith("perf") or lower.startswith("refactor"):
            other.append(msg)
        else:
            other.append(msg)
    return feat, fix, other


def gen_en(version: str) -> str:
    """Generate English changelog from git log since last tag."""
    messages = _git_log_since_tag()
    if not messages:
        return ""

    feat, fix, other = _classify_commits(messages)
    lines = []

    if feat:
        lines.append(f"### Added ({len(feat)})")
        for m in feat:
            lines.append(f"- {m}")
        lines.append("")

    if fix:
        lines.append(f"### Fixed ({len(fix)})")
        for m in fix:
            lines.append(f"- {m}")
        lines.append("")

    if other:
        lines.append(f"### Changed ({len(other)})")
        for m in other:
            lines.append(f"- {m}")
        lines.append("")

    return "\n".join(lines)


def gen_ar(version: str) -> str:
    """Generate Arabic changelog — simplified template."""
    messages = _git_log_since_tag()
    if not messages:
        return ""
    feat, fix, other = _classify_commits(messages)
    lines = []
    if feat:
        lines.append(f"### إضافات ({len(feat)})")
        for m in feat:
            # Strip conventional-commit prefix for cleaner display
            clean = m.split(":", 1)[-1].strip() if ":" in m else m
            lines.append(f"- {clean}")
        lines.append("")
    if fix:
        lines.append(f"### إصلاحات ({len(fix)})")
        for m in fix:
            clean = m.split(":", 1)[-1].strip() if ":" in m else m
            lines.append(f"- {clean}")
        lines.append("")
    if other:
        lines.append(f"### تغييرات ({len(other)})")
        for m in other:
            clean = m.split(":", 1)[-1].strip() if ":" in m else m
            lines.append(f"- {clean}")
        lines.append("")
    return "\n".join(lines)


def main():
    version = sys.argv[1] if len(sys.argv) > 1 else None

    # 1. Try manual entry from changelog.json
    try:
        with open(CHANGELOG_PATH) as f:
            data = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        data = {"versions": []}

    manual = None
    for entry in data.get("versions", []):
        if version and entry["version"] == version:
            manual = entry
            break

    if manual:
        # Manual entry exists — print it
        title = manual.get("title", f"Version {version}")
        print(f"## {title} (v{version})")
        print()
        for line in manual["changes"].get("en", []):
            print(f"- {line}")
        return

    # 2. Auto-generate from git log
    en_text = gen_en(version or "")

    if not en_text:
        print(f"## Version {version or '?'}")
        return

    print(f"## Changes (v{version})")
    print()
    print(en_text)


if __name__ == "__main__":
    main()
