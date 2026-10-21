#!/usr/bin/env bash
# Title of the focused window (empty on an empty workspace)
emit() {
  i3-msg -t get_tree | jq -r '[.. | objects | select(.focused == true and .window != null) | .name][0] // ""'
}
emit
i3-msg -t subscribe -m '["window","workspace"]' | while read -r _; do emit; done
