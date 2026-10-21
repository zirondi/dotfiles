#!/usr/bin/env bash
# Volume slider in the volume popup: click/drag sets the output volume
[ "$SENDER" = "mouse.clicked" ] && osascript -e "set volume output volume $PERCENTAGE"
