#!/bin/bash
# RTK Dashboard — data refresh
# Run via cron every 5 min: */5 * * * * /Users/rocordov/git/RTK-Dashboard/refresh.sh
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT_JSON="$SCRIPT_DIR/data/rtk-stats.json"
OUT_JS="$SCRIPT_DIR/data/rtk-stats.js"

python3 - "$OUT_JSON" "$OUT_JS" << 'PYEOF'
import json, re, subprocess, sys

def run(cmd):
    return subprocess.run(cmd, shell=True, capture_output=True, text=True).stdout

all_json = json.loads(run("rtk gain --all --format json 2>/dev/null"))
summary = all_json.get("summary", {})

text = run("rtk gain 2>/dev/null")
commands = []
in_section = False
for line in text.splitlines():
    if "By Command" in line:
        in_section = True
        continue
    if not in_section:
        continue
    if line.strip().startswith("──"):
        continue
    if not line.strip():
        break

    # Format: " 1.  rtk git status               13   1.2K   52.0%    26ms  ██████████"
    # Parse: number.  <command>  <count>  <saved>  <avg%>  <time>  <impact>
    m = re.match(r'\s*(\d+)\.\s+(.+?)\s+(\d+)\s+([\d.]+[KM]?)\s+([\d.]+%)\s+([\d.]+(?:ms|s))\s', line)
    if not m:
        continue

    cmd_name = m.group(2).strip()
    count = int(m.group(3))
    saved_str = m.group(4)
    avg_pct_str = m.group(5)
    time_str = m.group(6)

    if saved_str.endswith("K"):
        saved_tokens = int(float(saved_str[:-1]) * 1000)
    elif saved_str.endswith("M"):
        saved_tokens = int(float(saved_str[:-1]) * 1000000)
    else:
        saved_tokens = int(float(saved_str))

    avg_pct_num = float(avg_pct_str.rstrip("%"))

    if time_str.endswith("s") and not time_str.endswith("ms"):
        avg_time = int(float(time_str[:-1]) * 1000)
    elif time_str.endswith("ms"):
        avg_time = int(float(time_str[:-2]))
    else:
        avg_time = 0

    commands.append({
        "command": cmd_name,
        "count": count,
        "saved_tokens": saved_tokens,
        "avg_pct": avg_pct_num,
        "avg_time_ms": avg_time,
    })

result = {
    "summary": summary,
    "daily": all_json.get("daily", []),
    "weekly": all_json.get("weekly", []),
    "monthly": all_json.get("monthly", []),
    "by_command": commands,
}

with open(sys.argv[1], "w") as f:
    json.dump(result, f, indent=2)

with open(sys.argv[2], "w") as f:
    f.write("window.__RTK_DATA__ = ")
    json.dump(result, f, indent=2)
    f.write(";\n")

print(f"Wrote {len(commands)} commands, {summary.get('total_commands',0)} total, {len(all_json.get('daily',[]))} daily")
PYEOF

echo "[$(date -Iseconds)] RTK data refreshed"
