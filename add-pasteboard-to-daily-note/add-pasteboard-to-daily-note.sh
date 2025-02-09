#!/usr/bin/env bash

source ~/.zettelkasten/config

export LANG=en_US.UTF-8

dailyNoteDir="$ZETTELKASTEN_VAULT_DIR/Journal"
todaysDate=$(date +"%Y-%m-%d")
todaysTime=$(date +"%H:%M")

dailyNote=$dailyNoteDir"/"$todaysDate".md"
pasteboard=$(pbpaste)

dailyNoteEntry="- "$todaysTime": "$pasteboard

# Start Logging 
dirName="$(dirname "$0")"
scriptName="add-pasteboard-to-daily-note.sh"
timestamp=$(date +"%Y-%m-%d %H:%M:%S")

echo "$timestamp - $scriptName: Daily Note: $dailyNote" >> $dirName/execution.log
echo "$timestamp - $scriptName: Entry to Daily Note: $dailyNoteEntry" >> $dirName/execution.log
# End Logging

echo "$dailyNoteEntry" >> "$dailyNote"
