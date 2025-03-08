#!/usr/bin/env bash

dirName="$(dirname "$0")"
if ! [ -d "$dirName/logs" ] ; then
	mkdir "$dirName/logs"
fi

for i in {1..6}
do
	logDate=$(/opt/homebrew/bin/gdate "-d-$i days" +"%Y-%m-%d")
	logFile="$dirName/logs/pmset-sleep-wake_$logDate.log"
	if ! [ -f "$logFile" ] ; then
		pmset -g log | pmset -g log | grep -e "$logDate" |  grep -e " Sleep  " -e " Wake  " > $logFile 
	fi
done
