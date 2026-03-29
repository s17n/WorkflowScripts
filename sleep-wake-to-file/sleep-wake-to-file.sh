#!/usr/bin/env bash

set -u

scriptDir="$(cd "$(dirname "$0")" && pwd)"

usage() {
    cat <<'EOF'
Usage:
  ./sleep-wake-to-file.sh [--logs-root "/Pfad/zu/logs"]

Beschreibung:
  Exportiert Sleep/Wake-Events der letzten 6 Tage in Tages-Logs.
  Ohne --logs-root wird ./logs relativ zu diesem Skript verwendet.
EOF
}

logsRoot="$scriptDir/logs"

while [ $# -gt 0 ]; do
    case "$1" in
        --logs-root)
            shift
            if [ $# -eq 0 ]; then
                echo "Fehler: --logs-root erwartet einen Pfad." >&2
                usage >&2
                exit 1
            fi
            logsRoot="$1"
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

if ! command -v pmset >/dev/null 2>&1; then
    echo "Fehler: pmset ist nicht verfuegbar." >&2
    exit 1
fi

if command -v gdate >/dev/null 2>&1; then
    dateBin="$(command -v gdate)"
else
    echo "Fehler: gdate ist nicht verfuegbar." >&2
    exit 1
fi

mkdir -p "$logsRoot"

for i in {1..6}; do
    logDate="$("$dateBin" "-d-$i days" +"%Y-%m-%d")"
    logFile="$logsRoot/pmset-sleep-wake_$logDate.log"
    if [ ! -f "$logFile" ]; then
        pmset -g log | grep -e "$logDate" | grep -e " Sleep  " -e " Wake  " -e "Display is turned on" -e "Display is turned off" > "$logFile"
    fi
done
