#!/usr/bin/env bash
# i3 workspaces for the bars as JSON, keyed by monitor (each bar shows its own
# monitor's workspaces), re-emitted on every workspace and output event.
# Empty workspaces do not exist in i3, like the hidden ones in SketchyBar.
emit() {
  i3-msg -t get_workspaces | jq -c '
    sort_by(.num) | group_by(.output)
    | map({key: .[0].output, value: map({num, focused, visible, urgent})}) | from_entries'
}
emit
i3-msg -t subscribe -m '["workspace","output"]' | while read -r _; do emit; done
