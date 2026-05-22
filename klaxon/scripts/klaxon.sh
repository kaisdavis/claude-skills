#!/bin/bash
# klaxon.sh: triple Submarine alert with 1.333s pauses between plays.
#
# Use for "I REALLY need your attention" moments. The klaxon SKILL.md
# documents the calibration rules. Logs to ~/.claude/logs/audio-hook.log
# alongside per-ping play.sh entries.
#
# Args: optional reason string, appended to the log for audit.
# Usage: klaxon.sh "deploy gate waiting on approval"

REASON="${1:-unspecified}"
LOG="$HOME/.claude/logs/audio-hook.log"

mkdir -p "$(dirname "$LOG")"

TS=$(date '+%Y-%m-%d %H:%M:%S')
PARENT_CMD=$(ps -o command= -p "$PPID" 2>/dev/null | tr -s ' ' | cut -c1-120)

printf '[%s] KLAXON triple-ping reason=%q ppid=%s ppid_cmd=%q\n' \
  "$TS" "$REASON" "$PPID" "$PARENT_CMD" >> "$LOG"

# Route through play.sh so headless-suppression rules apply (a headless
# `claude -p` is never genuinely urgent for a human watching, log only).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for i in 1 2 3; do
  "$SCRIPT_DIR/play.sh" Submarine
  [ "$i" -lt 3 ] && sleep 1.333
done
