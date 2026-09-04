#!/usr/bin/env bash
# Boundary tests for play.sh's explicit-status mute. A nonexistent sound keeps
# the normal branch inaudible while its audit disposition remains observable.
set -uo pipefail

ROOT="$(mktemp -d "${TMPDIR:-/tmp}/klaxon-play-status.XXXXXX")"
trap 'rm -rf "$ROOT"' EXIT
HERE="$(cd "$(dirname "$0")" && pwd)"
PLAY="$HERE/play.sh"
LOG="$ROOT/home/.claude/logs/audio-hook.log"
STATUS="$ROOT/kai-status.txt"
PASS=0
FAIL=0

mkdir -p "$(dirname "$LOG")"

run_play() {
  HOME="$ROOT/home" KAI_STATUS_FILE="$STATUS" "$@" bash "$PLAY" NoSuchKlaxonSound
  tail -1 "$LOG"
}

expect_log() {
  local name="$1" want="$2" line="$3"
  if printf '%s' "$line" | grep -Fq "$want"; then
    printf 'ok - %s\n' "$name"
    PASS=$((PASS + 1))
  else
    printf 'not ok - %s: wanted %s in %s\n' "$name" "$want" "$line"
    FAIL=$((FAIL + 1))
  fi
}

expect_not_status_suppressed() {
  local name="$1" line="$2"
  if ! printf '%s' "$line" | grep -Eq 'afplay=skipped_status|suppress=suppressed_status'; then
    printf 'ok - %s\n' "$name"
    PASS=$((PASS + 1))
  else
    printf 'not ok - %s: status suppression remained in %s\n' "$name" "$line"
    FAIL=$((FAIL + 1))
  fi
}

printf '%s\n' 'kai said he was away from his computers' > "$STATUS"
line="$(run_play env)"
expect_log 'nonempty explicit status mutes urgent sound' 'afplay=skipped_status' "$line"
expect_log 'muted audit row includes the status sentence' 'status=kai\ said\ he\ was\ away\ from\ his\ computers' "$line"

: > "$STATUS"
line="$(run_play env)"
expect_not_status_suppressed 'empty status keeps the available sound path' "$line"

printf '%s\n' 'kai said he was heads down' > "$STATUS"
line="$(run_play env PLAY_IGNORE_STATUS=1)"
expect_not_status_suppressed 'explicit override bypasses only status suppression' "$line"

printf '%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
