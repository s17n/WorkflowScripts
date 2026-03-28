#!/usr/bin/env bash

set -u

scriptDir="$(cd "$(dirname "$0")" && pwd)"
syncScript="$scriptDir/sync-daily-note-frontmatter.py"

usage() {
    cat <<'EOF'
Usage:
  ./sync-date-range.sh --daily-root "/Pfad/zu/DailyNotes" --start-date YYYY-MM-DD --end-date YYYY-MM-DD

Beschreibung:
  Ruft sync-daily-note-frontmatter.py fuer alle Tage einer inklusiven
  Date-Range auf.
EOF
}

dailyRoot=""
startDate=""
endDate=""

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
        --start-date)
            shift
            if [ $# -eq 0 ]; then
                echo "Fehler: --start-date erwartet ein Datum im Format YYYY-MM-DD." >&2
                usage >&2
                exit 1
            fi
            startDate="$1"
            ;;
        --end-date)
            shift
            if [ $# -eq 0 ]; then
                echo "Fehler: --end-date erwartet ein Datum im Format YYYY-MM-DD." >&2
                usage >&2
                exit 1
            fi
            endDate="$1"
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

if [ -z "$startDate" ]; then
    echo "Fehler: --start-date ist erforderlich." >&2
    usage >&2
    exit 1
fi

if [ -z "$endDate" ]; then
    echo "Fehler: --end-date ist erforderlich." >&2
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
    python3 - "$startDate" "$endDate" <<'PY'
from datetime import datetime, timedelta
import sys

start_text = sys.argv[1]
end_text = sys.argv[2]
date_format = "%Y-%m-%d"

try:
    start_date = datetime.strptime(start_text, date_format).date()
except ValueError as exc:
    raise SystemExit(
        f"Fehler: Ungueltiger Wert fuer --start-date: {start_text}. Erwartet YYYY-MM-DD."
    ) from exc

try:
    end_date = datetime.strptime(end_text, date_format).date()
except ValueError as exc:
    raise SystemExit(
        f"Fehler: Ungueltiger Wert fuer --end-date: {end_text}. Erwartet YYYY-MM-DD."
    ) from exc

if start_date > end_date:
    raise SystemExit("Fehler: --start-date darf nicht spaeter als --end-date sein.")

current_date = start_date
while current_date <= end_date:
    print(current_date.isoformat())
    current_date += timedelta(days=1)
PY
)" || exit 1

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

if [ "$dateCount" -eq 0 ]; then
    echo "Fehler: Konnte keine Datumswerte fuer die angegebene Date-Range berechnen." >&2
    exit 1
fi

exit "$overallStatus"
