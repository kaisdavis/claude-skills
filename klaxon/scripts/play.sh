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

# Remote detection: walk the process ancestry for a mosh-server or sshd. An
# urgent klaxon should reach Kai wherever he actually is — if the session is
# driven from another machine (laptop over mosh/ssh), this box's afplay speaker
# is the wrong place to blast it. The terminal bell below rides the tty stream
# to the attached terminal instead, so we ring the bell EVERYWHERE but only
# afplay when the session is local. (Mirrors ~/kaibot/scripts/audio/play.sh.)
REMOTE=""
if [ -z "$SUPPRESS" ]; then
  _p="$PPID"; _hops=0
  while [ -n "$_p" ] && [ "$_p" != "1" ] && [ "$_hops" -lt 12 ]; do
    case "$(ps -o command= -p "$_p" 2>/dev/null)" in
      *mosh-server*|*sshd*) REMOTE="remote_bell_only"; break ;;
    esac
    _p=$(ps -o ppid= -p "$_p" 2>/dev/null | tr -d ' ')
    _hops=$((_hops + 1))
  done
fi

# Effective disposition for the audit log (field name kept as `suppress=` so
# existing log readers don't break): headless wins, else remote, else played.
DISP="${SUPPRESS:-${REMOTE:-played}}"

printf '[%s] sound=%-10s suppress=%-22s ppid=%s ppid_cmd=%q gppid=%s gppid_cmd=%q\n' \
  "$TS" "$SOUND" "$DISP" "$PPID" "$PARENT_CMD" "$GPPID" "$GP_CMD" >> "$LOG"

# Terminal bell — a BEL byte rides the tty stream, so an urgent ping sounds on
# whichever machine currently owns the session: this box when local, the laptop
# over mosh/ssh. Target the claude process's controlling tty explicitly
# (/dev/ttysNNN); a hook does not reliably inherit /dev/tty. Headless has no
# interactive tty, so the case below no-ops.
if [ -z "$SUPPRESS" ]; then
  _tty=$(ps -o tty= -p "$PPID" 2>/dev/null | tr -d ' ')
  case "$_tty" in
    ttys*) printf '\a' > "/dev/$_tty" 2>/dev/null ;;
  esac
fi

# afplay fires only when the session is LOCAL to this box. A remote-driven
# session already got its bell on the attached terminal above.
if [ -z "$SUPPRESS" ] && [ -z "$REMOTE" ]; then
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
