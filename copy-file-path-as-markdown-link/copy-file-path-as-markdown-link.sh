#!/bin/zsh

filePath="$1"
app=$(xattr -p s17n.app $1)
# echo $filePath >> ~/Projects/Workflow-Tools/copy-file-path-as-markdown-link/debug.log
echo "[Screenshot - "$app"](file:"$filePath")" | pbcopy
