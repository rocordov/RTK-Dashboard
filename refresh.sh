#!/bin/bash
# RTK Dashboard — data refresh
# Run via cron every 5 min: */5 * * * * /Users/rocordov/git/RTK-Dashboard/refresh.sh
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# JSON file for programmatic consumers
rtk gain --all --format json > "$SCRIPT_DIR/data/rtk-stats.json" 2>/dev/null

# JS file for file:// dashboard (fetch() blocked from file:// protocol)
echo -n "window.__RTK_DATA__ = " > "$SCRIPT_DIR/data/rtk-stats.js"
rtk gain --all --format json >> "$SCRIPT_DIR/data/rtk-stats.js" 2>/dev/null
echo ";" >> "$SCRIPT_DIR/data/rtk-stats.js"

rtk session --format json > "$SCRIPT_DIR/data/rtk-sessions.json" 2>/dev/null
echo "[$(date -Iseconds)] RTK data refreshed"
