#!/usr/bin/env bash

source ~/.zettelkasten/config

for i in "$@"
do
case $i in
    -d=*|--dataview-key=*)
    dataviewKey="${i#*=}"
    ;;
    -e=*|--entry=*)
    entry="${i#*=}"
    ;;
    *)
            # unknown option
    ;;
esac
done

export LANG=en_US.UTF-8

dirName="$(dirname "$0")"
scriptName="add-reference-to-daily-note.sh"
timestamp=$(date +"%Y-%m-%d %H:%M:%S")

echo "$timestamp: $scriptName: Started - dataviewKey=$dataviewKey, entry=$entry" >> $dirName/logs/execution.log

dailyNoteDir="$ZETTELKASTEN_VAULT_DIR/Journal"
currentDate=$(date +"%Y-%m-%d")

dailyNote=$dailyNoteDir"/"$currentDate".md"

lineEntry=""

# get entry from clipboard if not provided
if [ "$entry" = "" ];  then
  entry=$(pbpaste)
fi

# dataview key not provided
if [ "$dataviewKey" = "" ];  then
  # and no plain markdown link -> DEVONthink link
  if ! [[ $entry == \[* ]]; then
    lineEntry=$(echo "$entry" | sed -E 's/(^[A-z]*:)/\1:/')
  # otherwise -> set Bookmarkl as default 
  else  
    dataviewKey="Bookmark"
  fi
fi

if [ "$lineEntry" = "" ]; then
  lineEntry="$dataviewKey:: $entry"
fi

dailyNoteEntry="- $lineEntry"
echo "$timestamp: $scriptName: Daily Note: $dailyNote" >> $dirName/logs/execution.log
echo "$timestamp: $scriptName: Entry: $dailyNoteEntry" >> $dirName/logs/execution.log

echo "$dailyNoteEntry" >> "$dailyNote"

echo "$timestamp: $scriptName: Finished" >> $dirName/logs/execution.log
