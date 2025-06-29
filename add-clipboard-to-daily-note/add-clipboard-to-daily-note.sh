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

dirName="$(dirname "$0")"
scriptName="add-clipboard-to-daily-note.sh"
timestamp=$(date +"%Y-%m-%d %H:%M:%S")

dailyNoteDir="$ZETTELKASTEN_VAULT_DIR/Journal"
currentDate=$(date +"%Y-%m-%d")

dailyNote=$dailyNoteDir"/"$currentDate".md"
pasteboard=$(pbpaste)

lineEntry=""
if ! [ "$dataviewKey" = "" ];  then
  lineEntry="$dataviewKey:: $pasteboard"
else
  if ! [[ $pasteboard == \[* ]]; then
    lineEntry=$(echo "$pasteboard" | sed -E 's/(^[A-z]*:)/\1:/')
  else 
    lineEntry="Bookmark:: $pasteboard"
  fi 
fi

dailyNoteEntry="- $lineEntry"
echo "$timestamp - $scriptName: Daily Note: $dailyNote" >> $dirName/logs/execution.log
echo "$timestamp - $scriptName: Entry: $dailyNoteEntry" >> $dirName/logs/execution.log

echo "$dailyNoteEntry" >> "$dailyNote"
