#!/usr/bin/env python3

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path


KEY_ORDER = (
    "firstScreenOn",
    "lastScreenOff",
    "duration",
    "durationOffScreen",
    "Start",
    "End",
    "breaktime",
    "worktime",
)
KEY_PATTERN = re.compile(r"^([A-Za-z0-9_-]+)\s*:(.*)$")
EMPTY_MARKERS = {"", "~", '""', "''"}


@dataclass
class SourceData:
    source_label: str
    payload: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Sync screentime metrics into daily-note frontmatter "
            "(keys: firstScreenOn, lastScreenOff, duration, durationOffScreen)."
        )
    )
    parser.add_argument(
        "--daily-root",
        required=True,
        help="Root directory for daily notes.",
    )
    parser.add_argument(
        "--date",
        required=True,
        help="Target day in format YYYY-MM-DD.",
    )
    parser.add_argument(
        "--workflow-root",
        help="Path to sleep-wake-to-file module (defaults to this script directory).",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show computed values and field actions without writing files.",
    )
    return parser.parse_args()


def parse_target_date(value: str) -> datetime:
    try:
        return datetime.strptime(value, "%Y-%m-%d")
    except ValueError as exc:
        raise SystemExit(f"Invalid --date value: {value}. Expected YYYY-MM-DD.") from exc


def resolve_workflow_root(args: argparse.Namespace) -> Path:
    if args.workflow_root:
        return Path(args.workflow_root).expanduser().resolve()
    return Path(__file__).resolve().parent


def load_source_data(workflow_root: Path, date_text: str) -> SourceData:
    log_path = workflow_root / "logs" / f"pmset-sleep-wake_{date_text}.log"
    if log_path.exists():
        payload = log_path.read_text(encoding="utf-8")
        return SourceData(source_label=f"log:{log_path}", payload=payload)

    result = subprocess.run(
        ["pmset", "-g", "log"],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        stderr = result.stderr.strip()
        raise RuntimeError(f"pmset failed ({result.returncode}): {stderr}")

    filtered_lines = []
    for line in result.stdout.splitlines():
        if date_text not in line:
            continue
        if " Sleep  " in line or " Wake  " in line:
            filtered_lines.append(line)

    payload = "\n".join(filtered_lines)
    if payload:
        payload += "\n"
    return SourceData(source_label="pmset-live", payload=payload)


def run_awk_metrics(awk_path: Path, payload: str) -> dict[str, str]:
    if not awk_path.exists():
        raise RuntimeError(f"AWK script not found: {awk_path}")

    result = subprocess.run(
        ["awk", "-v", "output=kv", "-f", str(awk_path)],
        check=False,
        capture_output=True,
        text=True,
        input=payload,
    )
    if result.returncode != 0:
        stderr = result.stderr.strip()
        raise RuntimeError(f"awk failed ({result.returncode}): {stderr}")

    values: dict[str, str] = {}
    for line in result.stdout.splitlines():
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip()
    return values


def to_hhmm(value: str) -> str:
    if value == "-":
        return value
    match = re.fullmatch(r"(\d{2}:\d{2})(?::\d{2})?", value)
    if match:
        return match.group(1)
    return value


def split_frontmatter(text: str) -> tuple[bool, list[str], str]:
    if not text:
        return False, [], ""

    lines = text.splitlines(keepends=True)
    if not lines:
        return False, [], ""
    if lines[0].strip() != "---":
        return False, [], text

    for idx in range(1, len(lines)):
        if lines[idx].strip() == "---":
            frontmatter_lines = lines[1:idx]
            body = "".join(lines[idx + 1 :])
            return True, frontmatter_lines, body

    return False, [], text


def parse_frontmatter_keys(frontmatter_lines: list[str]) -> dict[str, tuple[int, str]]:
    found: dict[str, tuple[int, str]] = {}
    for idx, line in enumerate(frontmatter_lines):
        if not line or line[0].isspace():
            continue
        match = KEY_PATTERN.match(line.rstrip("\n"))
        if not match:
            continue
        key = match.group(1).strip()
        raw_value = match.group(2).strip()
        if key not in found:
            found[key] = (idx, raw_value)
    return found


def is_unset(raw_value: str) -> bool:
    value = raw_value.strip()
    if not value:
        return True
    if value.startswith("#"):
        return True
    if value in EMPTY_MARKERS:
        return True
    if value.lower() == "null":
        return True
    return False


def plan_updates(
    existing: dict[str, tuple[int, str]], updates: dict[str, str]
) -> list[tuple[str, str, str]]:
    actions: list[tuple[str, str, str]] = []
    for key in KEY_ORDER:
        if key not in updates:
            continue
        if key not in existing:
            actions.append((key, "write", "missing"))
            continue
        _, raw_value = existing[key]
        if is_unset(raw_value):
            actions.append((key, "write", "empty"))
        else:
            actions.append((key, "skip", "already-set"))
    return actions


def apply_updates(
    frontmatter_lines: list[str],
    existing: dict[str, tuple[int, str]],
    updates: dict[str, str],
    actions: list[tuple[str, str, str]],
) -> list[str]:
    output = list(frontmatter_lines)
    for key, action, _reason in actions:
        if action != "write":
            continue
        line = f"{key}: {updates[key]}\n"
        if key in existing:
            idx, _ = existing[key]
            output[idx] = line
        else:
            output.append(line)
    return output


def build_document(frontmatter_lines: list[str], body: str) -> str:
    normalized_lines: list[str] = []
    for line in frontmatter_lines:
        if line.endswith("\n"):
            normalized_lines.append(line)
        else:
            normalized_lines.append(line + "\n")

    content = "---\n" + "".join(normalized_lines) + "---\n"
    if body:
        content += body
    return content


def build_note_path(daily_root: Path, target_date: datetime) -> Path:
    return daily_root / f"{target_date:%Y}" / f"{target_date:%m}" / f"{target_date:%Y-%m-%d}.md"


def print_summary(
    *,
    target_date: str,
    note_path: Path,
    source_label: str,
    computed: dict[str, str],
    actions: list[tuple[str, str, str]],
    dry_run: bool,
) -> None:
    mode = "DRY-RUN" if dry_run else "WRITE"
    print(f"Mode: {mode}")
    print(f"Date: {target_date}")
    print(f"Source: {source_label}")
    print(f"Note: {note_path}")
    print("Computed values (from AWK):")
    print(f"  first_screen_on: {computed['first_screen_on']}")
    print(f"  last_screen_off: {computed['last_screen_off']}")
    print(f"  duration: {computed['duration']}")
    print(f"  duration_off_screentime: {computed['duration_off_screentime']}")
    print("Field actions:")
    for key, action, reason in actions:
        print(f"  {key}: {action} ({reason})")


def main() -> int:
    args = parse_args()
    target_date = parse_target_date(args.date)
    date_text = target_date.strftime("%Y-%m-%d")

    workflow_root = resolve_workflow_root(args)
    daily_root = Path(args.daily_root).expanduser().resolve()
    daily_root.mkdir(parents=True, exist_ok=True)

    source_data = load_source_data(workflow_root, date_text)
    metrics = run_awk_metrics(workflow_root / "screentime.awk", source_data.payload)

    session_count = int(metrics.get("session_count", "0"))
    if session_count <= 0:
        print(f"No sessions found for {date_text}. Nothing to write.")
        return 0

    first_screen_on = to_hhmm(metrics.get("first_screen_on", "-"))
    last_screen_off = to_hhmm(metrics.get("last_screen_off", "-"))
    duration_on = metrics.get("duration", "00:00")
    duration_off = metrics.get("duration_off_screentime", "00:00")

    updates = {
        "firstScreenOn": first_screen_on,
        "lastScreenOff": last_screen_off,
        "duration": duration_on,
        "durationOffScreen": duration_off,
        "Start": first_screen_on,
        "End": last_screen_off,
        "breaktime": duration_off,
        "worktime": duration_on,
    }

    computed = {
        "first_screen_on": first_screen_on,
        "last_screen_off": last_screen_off,
        "duration": duration_on,
        "duration_off_screentime": duration_off,
    }

    note_path = build_note_path(daily_root, target_date)
    if note_path.exists():
        current_text = note_path.read_text(encoding="utf-8")
    else:
        current_text = ""

    _has_frontmatter, frontmatter_lines, body = split_frontmatter(current_text)
    existing = parse_frontmatter_keys(frontmatter_lines)
    actions = plan_updates(existing, updates)

    print_summary(
        target_date=date_text,
        note_path=note_path,
        source_label=source_data.source_label,
        computed=computed,
        actions=actions,
        dry_run=args.dry_run,
    )

    if args.dry_run:
        return 0

    if not any(action == "write" for _key, action, _reason in actions):
        print("Write result: no changes (all fields already set).")
        return 0

    updated_frontmatter_lines = apply_updates(frontmatter_lines, existing, updates, actions)
    new_document = build_document(updated_frontmatter_lines, body)

    note_path.parent.mkdir(parents=True, exist_ok=True)
    note_path.write_text(new_document, encoding="utf-8")
    print("Write result: file updated.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"Error: {exc}", file=sys.stderr)
        raise SystemExit(1)
