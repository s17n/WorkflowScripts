#!/usr/bin/env python3

from __future__ import annotations

"""Resolve a meeting note for a timestamp or fall back to a daily note.

The script is designed for Hazel-style automation:
- search recursively in a meeting-note tree
- match YAML frontmatter fields under `meeting`
- optionally append an entry to the resolved file
- fall back to a daily note file when no meeting matches
"""

import argparse
import sys
from datetime import date, datetime
from pathlib import Path

import frontmatter


TIMESTAMP_FORMAT = "%Y%m%d-%H%M%S"


def parse_args() -> argparse.Namespace:
    """Parse CLI arguments for meeting search and optional entry append."""
    parser = argparse.ArgumentParser(
        description="Find the first markdown file whose meeting frontmatter matches a timestamp."
    )
    parser.add_argument(
        "--root",
        help="Legacy shortcut: use the same root for meeting-note search and daily-note fallback.",
    )
    parser.add_argument(
        "--meeting-root",
        help="Root directory to search recursively for meeting notes.",
    )
    parser.add_argument(
        "--daily-root",
        help="Root directory for the fallback daily note YYYY-MM-DD.md.",
    )
    parser.add_argument(
        "--daily-only",
        action="store_true",
        help="Skip meeting-note lookup and always resolve the daily note for the timestamp.",
    )
    parser.add_argument(
        "--timestamp",
        required=True,
        help="Timestamp in the format YYYYMMDD-HHmmss.",
    )
    parser.add_argument(
        "--entry",
        help="Optional entry text to append to the resolved note target.",
    )
    return parser.parse_args()


def parse_timestamp(value: str) -> datetime:
    """Parse the incoming timestamp and normalize comparisons to minute precision."""
    try:
        return datetime.strptime(value, TIMESTAMP_FORMAT).replace(second=0)
    except ValueError as exc:
        raise SystemExit(f"Invalid timestamp format: {value}") from exc


def normalize_day(value: object) -> str | None:
    """Convert YAML-loaded day values into YYYY-MM-DD strings."""
    if isinstance(value, datetime):
        return value.date().isoformat()
    if isinstance(value, date):
        return value.isoformat()
    if isinstance(value, str):
        return value
    return None


def normalize_time(value: object) -> str | None:
    """Convert YAML-loaded time values into HH:MM strings.

    PyYAML may parse unquoted `HH:MM` values as minutes since midnight.
    """
    if isinstance(value, str):
        return value
    if isinstance(value, int):
        hours, minutes = divmod(value, 60)
        if 0 <= hours <= 23 and 0 <= minutes <= 59:
            return f"{hours:02d}:{minutes:02d}"
    return None


def extract_meeting_window(path: Path) -> tuple[datetime, datetime] | None:
    """Return the inclusive meeting window for a markdown file, if present."""
    try:
        post = frontmatter.load(path)
    except (OSError, UnicodeDecodeError):
        return None

    meeting = post.get("meeting")
    if not isinstance(meeting, dict):
        return None

    day = normalize_day(meeting.get("day"))
    start = normalize_time(meeting.get("start"))
    end = normalize_time(meeting.get("end"))
    if not all((day, start, end)):
        return None

    try:
        start_at = datetime.strptime(f"{day} {start}", "%Y-%m-%d %H:%M")
        end_at = datetime.strptime(f"{day} {end}", "%Y-%m-%d %H:%M")
    except ValueError:
        return None

    if start_at > end_at:
        return None

    return start_at, end_at


def resolve_matching_meeting_note(root: Path, target: datetime) -> Path | None:
    """Return the first lexicographically sorted meeting note matching the timestamp."""
    for path in sorted(root.rglob("*.md")):
        window = extract_meeting_window(path)
        if window is None:
            continue

        start_at, end_at = window
        if start_at <= target <= end_at:
            return path

    return None


def resolve_roots(args: argparse.Namespace) -> tuple[Path, Path]:
    """Resolve CLI roots while keeping `--root` as a compatibility shortcut."""
    meeting_root_arg = args.meeting_root or args.root
    daily_root_arg = args.daily_root or args.root

    if not args.daily_only and not meeting_root_arg:
        raise SystemExit("Missing required option: --meeting-root or --root")
    if not daily_root_arg:
        raise SystemExit("Missing required option: --daily-root or --root")

    meeting_root = (
        Path(meeting_root_arg).expanduser().resolve() if meeting_root_arg else Path()
    )
    daily_root = Path(daily_root_arg).expanduser().resolve()
    return meeting_root, daily_root


def ensure_roots(meeting_root: Path, daily_root: Path, *, daily_only: bool) -> bool:
    """Validate the meeting root and prepare the daily root if needed."""
    if not daily_only and not meeting_root.is_dir():
        print(f"Meeting root is not a directory: {meeting_root}", file=sys.stderr)
        return False
    if not daily_root.exists():
        daily_root.mkdir(parents=True, exist_ok=True)
    elif not daily_root.is_dir():
        print(f"Daily root is not a directory: {daily_root}", file=sys.stderr)
        return False
    return True


def build_daily_fallback_path(daily_root: Path, target: datetime) -> Path:
    """Build the fallback daily-note path from the normalized timestamp date."""
    return daily_root / f"{target:%Y-%m-%d}.md"


def append_entry(path: Path, entry: str) -> None:
    """Append the entry as a markdown list item, creating parent folders if needed."""
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(f"{entry}\n")


def main() -> int:
    args = parse_args()
    target = parse_timestamp(args.timestamp)
    meeting_root, daily_root = resolve_roots(args)

    if not ensure_roots(meeting_root, daily_root, daily_only=args.daily_only):
        return 1

    if args.daily_only:
        target_path = build_daily_fallback_path(daily_root, target)
    else:
        target_path = resolve_matching_meeting_note(meeting_root, target)
        if target_path is None:
            target_path = build_daily_fallback_path(daily_root, target)

    if args.entry:
        append_entry(target_path, args.entry)

    print(target_path)
    return 0


if __name__ == "__main__":
    sys.exit(main())
