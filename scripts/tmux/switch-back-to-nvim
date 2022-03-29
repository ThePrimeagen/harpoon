#!/usr/bin/env bash

# Make sure tmux is running
tmux_running=$(pgrep tmux)

if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    echo "tmux needs to be running"
    exit 1
fi

# Switch to a window called nvim in tmux - if it exists
session_name=$(tmux display-message -p "#S")

tmux switch-client -t "$session_name:nvim"
