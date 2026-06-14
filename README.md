# claude-skills

A collection of [Claude Code](https://claude.com/claude-code) skills I've built and open-sourced.

## What's in here

- **[`docs-update`](docs-update/SKILL.md)**: at the end of a work session in a repo with a multi-file doc set (3+ of README/CLAUDE/CONTEXT/ARCHITECTURE/DECISIONS/WORKLOG/TODO), routes each change to the right doc. Appends to WORKLOG, edits TODO, records decisions, updates ARCHITECTURE, adds glossary terms.
- **[`context-md`](context-md/SKILL.md)**: bootstraps and maintains a per-repo `CONTEXT.md` glossary, the ubiquitous-language layer for a project. Three modes: `init` (new), `update` (sharpen mid-session), `audit` (check against code). `docs-update` delegates glossary edits to it.
- **[`open-source-skill`](open-source-skill/SKILL.md)**: takes one of your internal markdown artifacts (a skill, slash command, prompt template, hook README) and ships a public, shareable version of it. A 6-category scrub checklist, an upfront-decisions structure, and a build-local-then-push-on-approval discipline. Has a lead-magnet variant.
- **[`klaxon`](klaxon/README.md)**: a three-tier audio attention system. Tink on every turn end, Sosumi when Claude Code waits on you, triple Submarine when Claude decides it really needs you. Includes a logger that records every chime + its parent process, and a suppression rule that silently drops chimes from headless `claude -p` subprocesses (scheduled prompts, queue workers) so they do not drown the signal.

`docs-update` and `context-md` are a matched pair; you can install either alone, but they pair well.

### Templates

Non-skill artifacts live under [`templates/`](templates/):

- **[`profile-interview`](templates/profile-interview/README.md)**: a guided interview that builds your personal Claude profile (the "who I am and how to talk to me" file) without the blank page. Paste it into a fresh Claude conversation, say "run this," and Claude interviews you one question at a time, leading with pick-a-style menus for voice and working style, then assembles the finished profile for you to save.

## Install

Skills live in `~/.claude/skills/` (available everywhere) or a project's `.claude/skills/` (that repo only):

```bash
# user-level — install all three
cp -r docs-update context-md open-source-skill ~/.claude/skills/

# or just the doc-discipline pair
cp -r docs-update context-md ~/.claude/skills/

# or just the publishing skill
cp -r open-source-skill ~/.claude/skills/
```

Restart Claude Code (or start a new session) so it picks them up.

## Use

Claude triggers each one from natural language, or you can invoke them explicitly:

| Skill | Slash invocation | Example natural-language triggers |
|---|---|---|
| `docs-update` | `/docs-update` | "catch up the docs", "the docs are stale", "wrap up and log this" |
| `context-md` | `/context-md` | "set up the glossary", "what do we call X", "audit our CONTEXT.md" |
| `open-source-skill` | `/open-source-skill` | "open source this skill", "publish this publicly", "turn this into a lead magnet" |
| `klaxon` | `/klaxon` | (autonomous) Claude fires when forward progress is blocked on you AND consequences exist if you do not see it soon |

All three doc/publishing skills preview their changes before writing or pushing, and the publishing skill waits for an explicit go-ahead before any outward action. `klaxon` is the one skill Claude fires by itself; it logs every fire so you can audit overuse.

## Credit

- The `CONTEXT.md` glossary format originates from the `grill-with-docs` skill in [mattpocock/skills](https://github.com/mattpocock/skills). See `skills/engineering/grill-with-docs/CONTEXT-FORMAT.md` there for the source-of-truth template.
- Pattern lifts in `open-source-skill` (publicly-installable check, common-gotchas format, credential pre-check) are from [alexknowshtml/claude-skills/publish-oss](https://github.com/alexknowshtml/claude-skills/blob/main/publish-oss/SKILL.md). `publish-oss` is the npm-package companion; this repo's `open-source-skill` is the markdown-artifact case.

## License

MIT. See [LICENSE](LICENSE).
