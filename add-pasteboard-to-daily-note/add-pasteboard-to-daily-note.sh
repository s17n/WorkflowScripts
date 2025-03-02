#!/usr/bin/env bash

source ~/.zettelkasten/config

for i in "$@"
do
case $i in
    -d=*|--dataview-key=*)
    dataviewKey="${i#*=}"
    ;;
    *)
            # unknown option
    ;;
esac
done

export LANG=en_US.UTF-8

dailyNoteDir="$ZETTELKASTEN_VAULT_DIR/Journal"
currentDate=$(date +"%Y-%m-%d")
currentTime=$(date +"%H:%M")

dailyNote=$dailyNoteDir"/"$currentDate".md"
pasteboard=$(pbpaste)

dailyNoteEntry="- $dataviewKey:: "$currentTime": "$pasteboard

# Start Logging 
dirName="$(dirname "$0")"
scriptName="add-pasteboard-to-daily-note.sh"
timestamp=$(date +"%Y-%m-%d %H:%M:%S")

echo "$timestamp - $scriptName: Daily Note: $dailyNote" >> $dirName/execution.log
echo "$timestamp - $scriptName: Entry to Daily Note: $dailyNoteEntry" >> $dirName/execution.log
# End Logging

echo "$dailyNoteEntry" >> "$dailyNote"
