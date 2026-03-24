#!/usr/bin/env python3

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path


TARGET_PATHS = (
    ("mac", "firstOn"),
    ("mac", "lastOff"),
    ("mac", "duration"),
    ("mac", "durationOff"),
    ("worktime", "start"),
    ("worktime", "end"),
    ("worktime", "break"),
)
TOP_LEVEL_PATTERN = re.compile(r"^([A-Za-z0-9_-]+)\s*:(.*)$")
NESTED_PATTERN = re.compile(r"^\s+([A-Za-z0-9_-]+)\s*:(.*)$")
TIME_PATTERN = re.compile(r"^(\d{2}):(\d{2})(?::\d{2})?$")
DURATION_PATTERN = re.compile(r"^(\d+):(\d{2})(?::\d{2})?$")
EMPTY_MARKERS = {"", "~", '""', "''"}


@dataclass
class SourceData:
    source_label: str
    payload: str


@dataclass
class SectionInfo:
    parent_index: int
    parent_raw: str
    block_end: int
    children: dict[str, tuple[int, str]]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Sync screentime metrics into daily-note frontmatter "
            "(keys: mac.firstOn, mac.lastOff, mac.duration, mac.durationOff)."
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


def to_iso8601_without_seconds(date_text: str, time_value: str) -> str:
    if time_value == "-":
        return time_value
    match = TIME_PATTERN.fullmatch(time_value)
    if not match:
        return time_value
    hour = match.group(1)
    minute = match.group(2)
    return f"{date_text}T{hour}:{minute}"


def to_duration_hm(value: str) -> str:
    sign = ""
    raw = value
    if raw.startswith("-"):
        sign = "-"
        raw = raw[1:]

    match = DURATION_PATTERN.fullmatch(raw)
    if not match:
        return value

    hours = int(match.group(1))
    minutes = int(match.group(2))
    return f"{sign}{hours}h{minutes:02d}m"


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


def parse_frontmatter_structure(
    frontmatter_lines: list[str],
) -> tuple[dict[str, tuple[int, str]], dict[str, SectionInfo]]:
    top_level: dict[str, tuple[int, str]] = {}
    sections: dict[str, SectionInfo] = {}

    for idx, line in enumerate(frontmatter_lines):
        if not line:
            continue
        if line[0].isspace():
            continue

        line_without_newline = line.rstrip("\n")
        match = TOP_LEVEL_PATTERN.match(line_without_newline)
        if not match:
            continue

        parent = match.group(1).strip()
        raw_value = match.group(2).strip()
        if parent not in top_level:
            top_level[parent] = (idx, raw_value)

        children: dict[str, tuple[int, str]] = {}
        block_end = idx + 1
        scan = idx + 1
        while scan < len(frontmatter_lines):
            child_line = frontmatter_lines[scan]
            if not child_line:
                break
            if not child_line[0].isspace():
                break

            child_without_newline = child_line.rstrip("\n")
            child_match = NESTED_PATTERN.match(child_without_newline)
            if child_match and not child_line.lstrip().startswith("#"):
                child_key = child_match.group(1).strip()
                child_raw = child_match.group(2).strip()
                if child_key not in children:
                    children[child_key] = (scan, child_raw)
            scan += 1
            block_end = scan

        if parent not in sections:
            sections[parent] = SectionInfo(
                parent_index=idx,
                parent_raw=raw_value,
                block_end=block_end,
                children=children,
            )

    return top_level, sections


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
    top_level: dict[str, tuple[int, str]],
    sections: dict[str, SectionInfo],
    updates: dict[str, str],
) -> list[tuple[str, str, str]]:
    actions: list[tuple[str, str, str]] = []

    for parent, child in TARGET_PATHS:
        path = f"{parent}.{child}"
        if path not in updates:
            continue

        if parent not in top_level:
            actions.append((path, "write", "missing-parent"))
            continue

        section = sections.get(parent)
        parent_raw = top_level[parent][1]
        child_entry = section.children.get(child) if section else None

        if child_entry:
            _idx, child_raw = child_entry
            if is_unset(child_raw):
                actions.append((path, "write", "empty-child"))
            else:
                actions.append((path, "skip", "already-set"))
            continue

        if parent_raw and not is_unset(parent_raw):
            actions.append((path, "skip", "parent-not-map"))
            continue

        actions.append((path, "write", "missing-child"))

    return actions


def apply_updates(
    frontmatter_lines: list[str],
    updates: dict[str, str],
    actions: list[tuple[str, str, str]],
) -> list[str]:
    action_by_path = {path: (action, reason) for path, action, reason in actions}
    output = list(frontmatter_lines)

    for parent, child in TARGET_PATHS:
        path = f"{parent}.{child}"
        decision = action_by_path.get(path)
        if decision is None:
            continue
        action, _reason = decision
        if action != "write":
            continue

        top_level, sections = parse_frontmatter_structure(output)
        child_line = f"  {child}: {updates[path]}\n"

        if parent in sections and child in sections[parent].children:
            child_index, _raw = sections[parent].children[child]
            output[child_index] = child_line
            continue

        if parent in top_level:
            parent_raw = top_level[parent][1]
            if parent_raw and not is_unset(parent_raw):
                continue
            insert_at = sections[parent].block_end if parent in sections else top_level[parent][0] + 1
            output.insert(insert_at, child_line)
            continue

        output.append(f"{parent}:\n")
        output.append(child_line)

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
    print("Computed values:")
    print(f"  mac.firstOn: {computed['mac.firstOn']}")
    print(f"  mac.lastOff: {computed['mac.lastOff']}")
    print(f"  mac.duration: {computed['mac.duration']}")
    print(f"  mac.durationOff: {computed['mac.durationOff']}")
    print("Field actions:")
    for path, action, reason in actions:
        print(f"  {path}: {action} ({reason})")


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

    first_on = to_iso8601_without_seconds(date_text, metrics.get("firstOn", "-"))
    last_off = to_iso8601_without_seconds(date_text, metrics.get("lastOff", "-"))
    duration_on = to_duration_hm(metrics.get("duration", "00:00"))
    duration_off = to_duration_hm(metrics.get("durationOff", "00:00"))

    updates = {
        "mac.firstOn": first_on,
        "mac.lastOff": last_off,
        "mac.duration": duration_on,
        "mac.durationOff": duration_off,
        "worktime.start": first_on,
        "worktime.end": last_off,
        "worktime.break": duration_off,
    }

    computed = {
        "mac.firstOn": first_on,
        "mac.lastOff": last_off,
        "mac.duration": duration_on,
        "mac.durationOff": duration_off,
    }

    note_path = build_note_path(daily_root, target_date)
    if note_path.exists():
        current_text = note_path.read_text(encoding="utf-8")
    else:
        current_text = ""

    _has_frontmatter, frontmatter_lines, body = split_frontmatter(current_text)
    top_level, sections = parse_frontmatter_structure(frontmatter_lines)
    actions = plan_updates(top_level, sections, updates)

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

    if not any(action == "write" for _path, action, _reason in actions):
        print("Write result: no changes (all fields already set).")
        return 0

    updated_frontmatter_lines = apply_updates(frontmatter_lines, updates, actions)
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
