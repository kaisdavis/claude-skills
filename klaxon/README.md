# klaxon

A three-tier audio attention system for [Claude Code](https://claude.com/claude-code), plus the `klaxon` skill that fires the loudest tier when Claude genuinely needs you.

## The problem

Claude Code is silent by default. Add a per-turn chime and it becomes ambient noise within a day, especially if you run multiple concurrent sessions or have scheduled `claude -p` workers in the background. Add no chime and you miss the moments when Claude is actually blocked on you.

The fix is a deliberate three-sound ladder:

| Tier | Sound | When | Fires per hour (typical) |
|---|---|---|---|
| Quiet | Tink (1x) | Every assistant turn ends. Stop hook. | 10-30 |
| Medium | Sosumi (1x) | Claude Code is waiting on you. Notification hook. | 1-5 |
| Loud | Submarine (3x, 1.333s pauses) | The `klaxon` skill. Claude decides this needs you NOW. | 0-1 |

The `klaxon` skill itself is the headline piece. The supporting scripts and hooks make it usable in a real setup where concurrent sessions and background `claude -p` workers would otherwise drown the signal.

## What you get

- **`SKILL.md`**: the `klaxon` skill. Claude fires it autonomously when forward progress is blocked on you AND consequences exist if you do not see it soon. Also fires on `/klaxon` for manual testing.
- **`scripts/play.sh`**: the canonical "play a sound" entry point. Logs every play (timestamp + parent process + grandparent), and suppresses (but still logs) when the parent is a headless `claude -p` subprocess. Wire your Stop and Notification hooks to call this.
- **`scripts/klaxon.sh`**: triple Submarine with 1.333s pauses. The skill calls this.
- **`settings-recipe.json`**: paste-able `hooks.Stop` and `hooks.Notification` entries for `~/.claude/settings.json`.

## Why the headless-suppression matters

If you have any `claude -p` workers running (scheduled prompts, cron jobs, queue workers, automated pipelines), each one fires the Stop hook on completion. With several workers running every few seconds you can hit a thousand-plus chimes per hour. The headless-suppression check in `play.sh` looks at the parent process command and silently drops audio (but logs the event) when the parent matches `claude -p` or `claude --print`. Interactive sessions still chime normally.

## Install

```bash
# Copy the skill into your global skills dir
cp -r klaxon ~/.claude/skills/

# Make the scripts executable
chmod +x ~/.claude/skills/klaxon/scripts/*.sh

# Smoke test the loud tier
~/.claude/skills/klaxon/scripts/klaxon.sh "install test"
```

Then wire the Stop and Notification hooks. Open `~/.claude/settings.json` and add the entries from `settings-recipe.json`. If your `hooks.Stop` array already exists, append; do not replace.

```jsonc
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/skills/klaxon/scripts/play.sh Tink"
          }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/skills/klaxon/scripts/play.sh Sosumi"
          }
        ]
      }
    ]
  }
}
```

Restart Claude Code (or start a new session) so the hook config is reloaded. You can confirm sounds are firing by tailing the log:

```bash
tail -f ~/.claude/logs/audio-hook.log
```

Each line records timestamp, sound name, played-or-suppressed, parent PID + command, grandparent PID + command. If chimes start firing from somewhere unexpected, this is where you look.

## Customize the sounds

Available macOS system sounds live at `/System/Library/Sounds/`:

```
Basso  Blow  Bottle  Frog  Funk  Glass  Hero
Morse  Ping  Pop  Purr  Sosumi  Submarine  Tink
```

Swap any sound name in the hook commands or in `klaxon.sh`. Test before committing:

```bash
afplay /System/Library/Sounds/Hero.aiff
```

## Use

Slash command:

```
/klaxon
```

Natural-language triggers Claude will recognize (per the skill's `description:` field):

- "ping me when this hits the deploy gate"
- "alert me if you find a prod incident"
- "I need to know right away if X"

Or Claude fires autonomously when it decides forward progress is blocked on you and the consequences warrant the loud tier.

## Calibration

Triple Submarine is heavy. If Claude fires it for something that did not deserve three Submarines, tell it so. The skill instructs Claude to log a reason string with every fire, so you can grep the log:

```bash
grep "KLAXON triple-ping" ~/.claude/logs/audio-hook.log
```

Eyeball the reasons. If half of them are routine, Claude is over-firing; correct in conversation and the calibration will drift back.

## License

MIT. See `../LICENSE`.
