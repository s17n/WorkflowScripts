#!/usr/bin/env bash

source /Users/steffen/.zettelkasten/config

sourceDir="$ZETTELKASTEN_VAULT_DIR"
destDir="$ZETTELKASTEN_BACKUP_DIR"

exclude=".DS_Store"

dirName="$(dirname "$0")"
if ! [ -d "$dirName/logs" ] ; then
	mkdir "$dirName/logs"
fi
executionDate=$(date +%Y%m%d-%H%M%S)
logFile="$dirName/logs/$executionDate.log"

rsync -ai --delete --exclude="$exclude" "$sourceDir/" "$destDir" >> "$logFile"
