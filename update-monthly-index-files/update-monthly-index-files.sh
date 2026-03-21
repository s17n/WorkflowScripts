#!/usr/bin/env bash

KIND="Assets"
INDEX_FILES_DIR="/Users/steffen/Library/Mobile Documents/iCloud~md~obsidian/Documents/Zettelkasten/References/$KIND"

BASE_DIR="$1"
EVENTS_DIR="$BASE_DIR/Updates"

for file in "$EVENTS_DIR"/*; do

  name=$(basename "$file")
  [[ $name =~ ^[0-9]{6}$ ]] || continue

  YYYY=${name:0:4}
  MM=${name:4:2}

  echo "Datei: $name → Jahr: $YYYY, Monat: $MM"
  DATA_DIR="$BASE_DIR/$YYYY/$MM"

  mkdir -p "$INDEX_FILES_DIR/$YYYY"
  find "$DATA_DIR" -name "*.md" -print0 | sort -z | xargs  -0 cat > "$INDEX_FILES_DIR/$YYYY/$YYYY-$MM.md"

  rm "$file"
done