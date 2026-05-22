#!/bin/bash
# play.sh: play a macOS system sound and log who triggered it.
#
# Usage: play.sh <SoundName>
#   <SoundName> is the basename (no extension) of a file under
#   /System/Library/Sounds/. Examples: Tink, Pop, Glass, Sosumi, Submarine, Frog.
#
# Log: ~/.claude/logs/audio-hook.log (created on first write)
#   Each line records timestamp, sound, parent PID + command, grandparent PID +
#   command. Useful when chimes start firing from unexpected sources.
#
# Suppression: when the parent is a headless `claude -p` (or `claude --print`)
#   invocation, the chime is suppressed but still logged. Rationale: those
#   subprocesses fire constantly in some setups (scheduled prompts, cron-like
#   workers, automated pipelines) and would drown the user. Interactive sessions
#   still chime normally.

SOUND="${1:-Tink}"
LOG="$HOME/.claude/logs/audio-hook.log"
SOUND_PATH="/System/Library/Sounds/${SOUND}.aiff"

mkdir -p "$(dirname "$LOG")"

TS=$(date '+%Y-%m-%d %H:%M:%S')
PARENT_CMD=$(ps -o command= -p "$PPID" 2>/dev/null | tr -s ' ' | cut -c1-120)
GPPID=$(ps -o ppid= -p "$PPID" 2>/dev/null | tr -d ' ')
GP_CMD=$(ps -o command= -p "$GPPID" 2>/dev/null | tr -s ' ' | cut -c1-120)

SUPPRESS=""
case "$PARENT_CMD" in
  *"claude -p"*|*"claude --print"*) SUPPRESS="suppressed_headless" ;;
esac

printf '[%s] sound=%-10s suppress=%-22s ppid=%s ppid_cmd=%q gppid=%s gppid_cmd=%q\n' \
  "$TS" "$SOUND" "${SUPPRESS:-played}" "$PPID" "$PARENT_CMD" "$GPPID" "$GP_CMD" >> "$LOG"

if [ -z "$SUPPRESS" ]; then
  # Use absolute path so this works even when a shadowed afplay is on PATH.
  /usr/bin/afplay "$SOUND_PATH" &
fi
