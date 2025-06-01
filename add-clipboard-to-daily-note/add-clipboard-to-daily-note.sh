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
currentTime=$(date +"%H:%M")

dailyNote=$dailyNoteDir"/"$currentDate".md"
pasteboard=$(pbpaste)
currentDataviewKey=$(cat "$dirName/../.current-dataview-key")
# echo "dirName: "$dirName
# echo "currentDataviewKey: "$currentDataviewKey
# echo "pasteboard: "$pasteboard

if [ "$dataviewKey" = "" ];  then
  dataviewKey="$currentDataviewKey"
fi
# echo "dataviewKey: "$dataviewKey
dailyNoteEntry="- $dataviewKey:: "$currentTime": "$pasteboard

echo "$timestamp - $scriptName: Daily Note: $dailyNote" >> $dirName/logs/execution.log
echo "$timestamp - $scriptName: Entry to Daily Note: $dailyNoteEntry" >> $dirName/logs/execution.log

echo "$dailyNoteEntry" >> "$dailyNote"
