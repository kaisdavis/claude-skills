---
name: klaxon
description: Fire a loud triple-Submarine alert when Claude genuinely needs the user's attention RIGHT NOW. Use sparingly. Triggers when forward progress is blocked on the user specifically AND consequences exist if they do not see it soon. Examples: about to take an irreversible action and need explicit approval, prod incident discovered mid-task, deploy gate waiting on real-eyes sign-off, long-running operation idled waiting on input for more than two turns. Also fires on `/klaxon` for manual testing. Skip for normal turn-end chimes (the Stop hook covers that) and routine clarifying questions (the Notification hook covers that). Skip entirely in headless `claude -p` contexts where no human is watching.
allowed-tools: Bash
---

# klaxon: "I REALLY need your attention"

Triple-ping the macOS Submarine system sound with 1.333s pauses. Every fire is logged with timestamp, parent process, and reason to `~/.claude/logs/audio-hook.log`, so the user can audit overuse.

## Why this skill exists

Claude Code's default audio is silent. Many users wire a Stop-hook chime (every turn ends), and some wire a Notification-hook chime (when Claude Code is waiting on you). Both fire often enough that they fade into ambient noise. There needs to be a third tier: a sound the user reaches for once an hour at most, that genuinely cuts through.

That third tier is this skill. Triple Submarine is intentionally heavier than a normal alert. If you fire it for a non-emergency the user will tell you, and you should recalibrate.

## When to fire (autonomous)

ALL three must be true:

1. **Forward progress is blocked on the user specifically.** Not "I finished a turn." A real human-in-the-loop gate.
2. **Consequences exist if they do not see it soon.** Destructive op queued, incident in flight, deploy gate, security finding, irreversible action pending.
3. **Tink (Stop) and Sosumi (Notification) would be too quiet for the gravity.** If the situation would be served by a normal chime, use the normal chime.

Concrete examples:

- About to push to a production branch and need explicit ship approval. Fire BEFORE asking.
- Discovered live data loss or a running prod incident mid-task.
- A long-running operation has been blocked waiting on user input for more than two turns.
- About to take an irreversible action (force-push, db drop, mass delete) and need real-eyes confirmation.

Skip for:

- Every turn end. That is the Stop chime, automatic.
- "Done with the task." Silence is fine; the diff is the report.
- Routine clarifying questions. Those are Notification territory.
- Headless `claude -p` contexts. No human is watching, this is a no-op.

## How to fire

```bash
~/.claude/skills/klaxon/scripts/klaxon.sh "short reason for the audit log"
```

The reason string lands in `~/.claude/logs/audio-hook.log` under the `KLAXON triple-ping` header so the user can audit calibration. If you fired it for something that did not deserve three Submarines, expect to be called out and dial back.

## Manual trigger

User typing `/klaxon` should fire `~/.claude/skills/klaxon/scripts/klaxon.sh "manual test"`. Smoke test for the chain.

## Companion hooks (recommended bundle)

This skill is most useful as the loudest tier of a three-sound ladder:

| Tier | Sound | When |
|---|---|---|
| Quiet | Tink (1x) | Every assistant turn ends. Stop hook. |
| Medium | Sosumi (1x) | Claude Code is waiting on user input. Notification hook. |
| Loud | Submarine (3x, 1.333s pauses) | This skill. |

The companion script at `scripts/play.sh` (logger + headless suppression) plus the `settings-recipe.json` hook block wire up the quiet and medium tiers. See README.md in this skill's repo for the full install.
