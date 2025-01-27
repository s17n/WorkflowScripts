#!/bin/zsh

filePath="$1"
# echo $filePath >> ~/Projects/Workflow-Tools/copy-file-path-as-markdown-link/debug.log
echo "[Screenshot](file:"$filePath")" | pbcopy
