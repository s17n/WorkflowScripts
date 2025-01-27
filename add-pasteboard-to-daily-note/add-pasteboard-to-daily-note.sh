#!/bin/zsh

export LANG=en_US.UTF-8

dailyDir="/Users/steffen/Library/Mobile Documents/iCloud~md~obsidian/Documents/Zettelkasten/Journal"
todayDate=$(date +"%Y-%m-%d")
todayTime=$(date +"%H:%M")

dailyNote=$dailyDir"/"$todayDate".md"
pasteboard=$(pbpaste)

echo "- "$todayTime": "$pasteboard  >> $dailyNote


