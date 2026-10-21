#!/usr/bin/env bash
# i3 workspaces as JSON for the bar, re-emitted on every workspace event.
# Empty workspaces do not exist in i3, like the hidden ones in SketchyBar.
emit() {
  i3-msg -t get_workspaces | jq -c '[.[] | {num, focused, urgent}] | sort_by(.num)'
}
emit
i3-msg -t subscribe -m '["workspace","output"]' | while read -r _; do emit; done
