#!/bin/bash
# RTK Dashboard — data refresh
# Run via cron every 5 min: */5 * * * * /Users/rocordov/git/RTK-Dashboard/refresh.sh
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
rtk gain --all --format json > "$SCRIPT_DIR/data/rtk-stats.json" 2>/dev/null
rtk session --format json > "$SCRIPT_DIR/data/rtk-sessions.json" 2>/dev/null
echo "[$(date -Iseconds)] RTK data refreshed"
