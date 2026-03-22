#!/usr/bin/env bash

dirName="$(cd "$(dirname "$0")" && pwd)"

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

mkdir -p "$dirName/logs"

for i in {1..6}
do
	logDate="$("$dateBin" "-d-$i days" +"%Y-%m-%d")"
	logFile="$dirName/logs/pmset-sleep-wake_$logDate.log"
	if ! [ -f "$logFile" ] ; then
		pmset -g log | grep -e "$logDate" | grep -e " Sleep  " -e " Wake  " > "$logFile"
	fi
done
