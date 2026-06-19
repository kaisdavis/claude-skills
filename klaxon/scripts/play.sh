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
  # Absolute path so this works even when a shadowed afplay is on PATH.
  #
  # Detach ALL of afplay's std{in,out,err} from the inherited pipes. This script
  # runs as a Stop/Notification hook (and the klaxon fires it 3x back-to-back):
  # Claude Code waits for the hook's stdout to hit EOF before the hook is "done".
  # A bare `afplay &` leaves the backgrounded afplay holding the hook's stdout fd,
  # so if afplay wedges (audio device contention / unavailable output device) the
  # pipe never closes and Claude Code blocks forever on "running stop hooks".
  # Detaching the fds makes the hook return instantly regardless of afplay's fate.
  /usr/bin/afplay "$SOUND_PATH" >/dev/null 2>&1 </dev/null &
  ap=$!
  # Watchdog: a system sound is <2s; if afplay is still alive after 10s the audio
  # device is wedged. Kill it so stuck players can't accumulate (the rapid triple-
  # ping makes pile-up the failure mode). Fully detached so it never holds the
  # hook open either.
  ( sleep 10; kill "$ap" 2>/dev/null ) >/dev/null 2>&1 </dev/null &
fi
