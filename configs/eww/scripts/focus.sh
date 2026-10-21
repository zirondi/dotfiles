#!/usr/bin/env bash
# Linux side of macOS Focus: true while dunst notifications are paused
[ "$(dunstctl is-paused 2>/dev/null)" = "true" ] && echo true || echo false
