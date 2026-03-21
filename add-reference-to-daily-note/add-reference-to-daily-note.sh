#!/usr/bin/env bash

source ~/.zettelkasten/config

export LANG=en_US.UTF-8

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME="$(basename "$0")"
LOG_FILE="$SCRIPT_DIR/logs/execution.log"

dataview_key=""
entry=""
target_date=""

log() {
  local message="$1"
  local timestamp
  timestamp="$(date +"%Y-%m-%d %H:%M:%S")"
  echo "$timestamp: $SCRIPT_NAME: $message" >> "$LOG_FILE"
}

usage() {
  cat <<'EOF'
Usage:
  add-reference-to-daily-note.sh [--date=YYYY-MM-DD] [--dataview-key=KEY] [--entry=TEXT]

Options:
  --date=YYYY-MM-DD      Write to the specified daily note. Defaults to today.
  -d=KEY
  --dataview-key=KEY     Prefix the entry with a Dataview field, e.g. Bookmark.
  -e=TEXT
  --entry=TEXT           Entry content. If omitted, the script reads from the clipboard.
  -h
  --help                 Show this help text.
EOF
}

parse_args() {
  local arg

  for arg in "$@"; do
    case "$arg" in
      --date=*)
        target_date="${arg#*=}"
        ;;
      -d=*|--dataview-key=*)
        dataview_key="${arg#*=}"
        ;;
      -e=*|--entry=*)
        entry="${arg#*=}"
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown option: $arg" >&2
        usage >&2
        exit 1
        ;;
    esac
  done
}

require_config() {
  if [ -z "${ZETTELKASTEN_VAULT_DIR:-}" ]; then
    echo "ZETTELKASTEN_VAULT_DIR is not set in ~/.zettelkasten/config" >&2
    exit 1
  fi
}

resolve_target_date() {
  if [ -z "$target_date" ]; then
    target_date="$(date +"%Y-%m-%d")"
  fi
}

resolve_daily_note_path() {
  local daily_note_dir
  daily_note_dir="$ZETTELKASTEN_VAULT_DIR/Journal"
  printf '%s/%s.md\n' "$daily_note_dir" "$target_date"
}

read_entry_from_clipboard_if_needed() {
  if [ -z "$entry" ]; then
    entry="$(pbpaste)"
  fi
}

build_line_entry() {
  # Markdown links get a default Dataview key when none was provided.
  if [ -z "$dataview_key" ] && [[ "$entry" == \[* ]]; then
    dataview_key="Bookmark"
  fi

  # Entries without a Dataview key are written as-is. This keeps DEVONthink
  # style content and other plain text untouched.
  if [ -z "$dataview_key" ]; then
    printf '%s\n' "$entry"
    return
  fi

  printf '%s:: %s\n' "$dataview_key" "$entry"
}

append_entry_to_daily_note() {
  local daily_note="$1"
  local line_entry="$2"

  mkdir -p "$(dirname "$daily_note")"
  touch "$daily_note"

  printf -- '- %s\n' "$line_entry" >> "$daily_note"
}

main() {
  local daily_note
  local line_entry

  parse_args "$@"
  require_config
  resolve_target_date
  read_entry_from_clipboard_if_needed

  if [ -z "$entry" ]; then
    echo "Entry is empty." >&2
    exit 1
  fi

  daily_note="$(resolve_daily_note_path)"
  line_entry="$(build_line_entry)"

  log "Started - date=$target_date, dataviewKey=$dataview_key, entry=$entry"
  log "Daily Note: $daily_note"
  log "Entry: - $line_entry"

  append_entry_to_daily_note "$daily_note" "$line_entry"

  log "Finished"
}

main "$@"
