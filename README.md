# WorkflowScripts

Collection of small macOS automation scripts for daily information workflows
with Obsidian, DEVONthink, Finder, and Calendar.

Compared to [MailScripts](https://github.com/s17n/MailScripts), this repository
has a broader scope and focuses on information management workflows.

Each script is intentionally small and isolated. The scripts are most useful
when combined in recurring routines (Quick Actions, PopClip, LaunchBar, cron,
etc.).

## Prerequisites

- macOS (many scripts use AppleScript, `defaults`, `pbpaste`, `pmset`)
- Bash (`#!/usr/bin/env bash`)
- Optional Homebrew tools for specific scripts:
  - `gdate` (GNU date)
  - `rsync` (Homebrew path is used in one script)
- Local configuration for Zettelkasten-based workflows:
  - `~/.zettelkasten/config`

## Scripts and Components

### Documented components

- [Add Reference to Note](./add-reference-to-note/README.md)  
  Adds formatted references to a matching meeting note or falls back to the
  daily note for the given timestamp.
- [Create Markdown Link](./create-markdown-link/README.md)  
  Creates app-specific markdown links (DEVONthink/Finder/clipboard).
- [Create Meeting Note](./create-meeting-note/README.md)  
  Creates markdown meeting notes from calendar entries.
- [DEVONthink CSS](./devonthink-css/README.md)  
  CSS profile for DEVONthink markdown rendering.
- [Sleep Wake to File](./sleep-wake-to-file/README.md)  
  Exports sleep/wake events from `pmset` to daily log files.

### Additional scripts (currently without dedicated README)

- [export-embeddings/export-embeddings.sh](./export-embeddings/export-embeddings.sh)  
  Rewrites local file links in exported markdown and copies attachments.
- [get-name-of-frontmost-app/Get Name of Frontmost App.scpt](./get-name-of-frontmost-app/Get%20Name%20of%20Frontmost%20App.scpt)  
  Returns the name of the frontmost macOS app.
- [rsync-zettelkasten/rsync-zettelkasten.sh](./rsync-zettelkasten/rsync-zettelkasten.sh)  
  Mirrors a Zettelkasten vault to backup destination via `rsync`.
- [tag-file-with-frontmost-app/Tag File with Frontmost App.scpt](./tag-file-with-frontmost-app/Tag%20File%20with%20Frontmost%20App.scpt)  
  Tags files based on the current frontmost app context.
- [toggle-stage-manager/toggle-stage-manager.sh](./toggle-stage-manager/toggle-stage-manager.sh)  
  Toggles Stage Manager on/off via macOS defaults.
- [split-pages/toggle-stage-manager.sh](./split-pages/toggle-stage-manager.sh)  
  Duplicate toggle script with identical behavior.
- [update-monthly-index-files/update-monthly-index-files.sh](./update-monthly-index-files/update-monthly-index-files.sh)  
  Regenerates monthly index files from update markers.
- [config/config.scpt](./config/config.scpt)  
  Compiled AppleScript configuration constants used by the workflows.

## Repository Notes

- AppleScript files (`*.scpt`) are committed as compiled scripts.
- Runtime logs are written by several scripts into local `logs/` folders.
- `.log` files are ignored by git via `.gitignore`.
