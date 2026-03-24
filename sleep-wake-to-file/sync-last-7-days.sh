#!/usr/bin/env bash

set -u

scriptDir="$(cd "$(dirname "$0")" && pwd)"
syncScript="$scriptDir/sync-daily-note-frontmatter.py"

usage() {
    cat <<'EOF'
Usage:
  ./sync-last-7-days.sh --daily-root "/Pfad/zu/DailyNotes"

Beschreibung:
  Ruft sync-daily-note-frontmatter.py fuer die letzten 7 Tage auf
  (ohne den aktuellen Tag).
EOF
}

dailyRoot=""

while [ $# -gt 0 ]; do
    case "$1" in
        --daily-root)
            shift
            if [ $# -eq 0 ]; then
                echo "Fehler: --daily-root erwartet einen Pfad." >&2
                usage >&2
                exit 1
            fi
            dailyRoot="$1"
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Fehler: Unbekanntes Argument '$1'." >&2
            usage >&2
            exit 1
            ;;
    esac
    shift
done

if [ -z "$dailyRoot" ]; then
    echo "Fehler: --daily-root ist erforderlich." >&2
    usage >&2
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "Fehler: python3 ist nicht verfuegbar." >&2
    exit 1
fi

if [ ! -f "$syncScript" ]; then
    echo "Fehler: Sync-Skript nicht gefunden: $syncScript" >&2
    exit 1
fi

targetDates="$(
    python3 - <<'PY'
from datetime import date, timedelta

today = date.today()
for offset in range(1, 8):
    print((today - timedelta(days=offset)).isoformat())
PY
)"

overallStatus=0
dateCount=0

while IFS= read -r targetDate; do
    if [ -z "$targetDate" ]; then
        continue
    fi
    dateCount=$((dateCount + 1))
    printf "Sync date: %s\n" "$targetDate"
    if ! python3 "$syncScript" --daily-root "$dailyRoot" --date "$targetDate"; then
        printf "Fehler: Sync fehlgeschlagen fuer %s\n" "$targetDate" >&2
        overallStatus=1
    fi
done <<EOF
$targetDates
EOF

if [ "$dateCount" -ne 7 ]; then
    echo "Fehler: Konnte Datumswerte fuer die letzten 7 Tage nicht berechnen." >&2
    exit 1
fi

exit "$overallStatus"
