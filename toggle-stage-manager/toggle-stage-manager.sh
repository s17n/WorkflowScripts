#!/usr/bin/env bash

toggle=$(defaults read com.apple.WindowManager GloballyEnabled)
if [[ "$toggle" == "1" ]]; then
    $(defaults write com.apple.WindowManager GloballyEnabled -bool false)
else
    $(defaults write com.apple.WindowManager GloballyEnabled -bool true)
fi