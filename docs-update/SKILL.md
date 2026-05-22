---
name: docs-update
description: Use when finishing a session in a repo with a multi-file doc set (any 3+ of README.md, CLAUDE.md, CONTEXT.md, ARCHITECTURE.md, DECISIONS.md, WORKLOG.md, TODO.md) and the docs are behind the code. Routes each delta to the right file: appends to WORKLOG, edits TODO, records decisions, adds CONTEXT terms, updates ARCHITECTURE. Triggers on the user saying "catch up the docs", "sync the docs", "update the docs", "doc catch-up", "bring the docs current", "the docs are stale", "what about docs", "wrap up", "log this work", or invoking `/docs-update`. Pairs with the `context-md` skill (the CONTEXT.md-specific worker docs-update delegates to for glossary edits). Skip in single-doc repos (README only) and in repos with no doc set yet (use `context-md` first).
---

# docs-update

Catch up the per-repo doc set with what actually happened this session. Read commits, code delta, worklog, and the chat arc; update each doc by appending the right kind of change to the right file.

The whole point: every doc has a job. Don't pile updates into whichever doc is closest. Route the right change to the right file.

## When to use

- End of a work session in a repo with 3+ of the canonical docs above.
- The user says "catch up the docs", "sync docs", "doc catch-up", or invokes `/docs-update`.

## When NOT to use

- Repo has only README.md (single-doc repo). Just update the README in place; no skill needed.
- Mid-session refactor without a meaningful arc yet. Wait for the work to land.
- After a one-line fix that doesn't shift docs (typo, lint, dependency bump).

## Process

### 1. Inventory

```bash
ls *.md | grep -E '^(README|CLAUDE|CONTEXT|ARCHITECTURE|DECISIONS|WORKLOG|TODO)\.md$'
```

Note which of the 7 are present. Other md files (CHANGELOG, CONTRIBUTING, etc.) are out of scope for this skill.

### 2. Read each one

Don't guess shape from filename. Read the actual file. Note its current structure and which section is the append target (e.g. WORKLOG has a today-dated section; TODO has Open and Recently shipped).

### 3. Survey session changes

```bash
git log --oneline <since-marker>..HEAD       # commits this session
git diff --stat <since-marker>..HEAD          # files touched
git status --short                            # uncommitted
```

For `<since-marker>`: prior session's last commit, or today's first commit. Fall back to "last 24h" if unsure (`--since='24 hours ago'`).

Use the in-context session arc (what happened in chat) as primary source of intent. The git log gives the artifacts.

### 4. Per-doc decision rules

For each doc that exists, decide: append, edit, or skip.

| File | Append/edit when |
|---|---|
| **WORKLOG.md** | Always (if any code shipped). One paragraph under today's date heading. New `## YYYY-MM-DD` section if no entry for today. |
| **TODO.md** | When new open items surfaced OR existing items were shipped. Strike with `~~~~` OR move to "Recently shipped" section. Add new items to "Open". |
| **DECISIONS.md** | Only when a new design decision passes the 3-gate: hard to reverse, surprising without context, real trade-off. Otherwise skip. Most commits don't warrant a new decision entry. |
| **CONTEXT.md** | When new domain vocabulary was introduced. New noun in the system, new verb in the workflow, new flagged ambiguity. NOT for general programming concepts. (Delegate to the `context-md` skill.) |
| **ARCHITECTURE.md** | When module map changed (new file in src/), phase count changed, new external integration added, or storage shape changed. |
| **README.md** | When operator-facing surface changed: new CLI flag, new env var, new install step, new run command. Architecture section update only if ARCHITECTURE.md changed and you want them mirrored. |
| **CLAUDE.md** | When a new convention was established that future-session-Claude needs to know. Rare. Most session learnings belong in a memory system, not CLAUDE.md. |

### 5. Preview

Before writing, show the user a one-line summary per doc:

```
docs-update preview:
  WORKLOG.md:     +1 entry under 2026-05-17 (slice B, link-mode, duration fix)
  TODO.md:        +1 open (non-Shorts handling), 0 struck
  DECISIONS.md:   no change
  CONTEXT.md:     +2 terms (Link-mode, Persona facts)
  ARCHITECTURE.md: no change
  README.md:      no change
  CLAUDE.md:      no change

proceed? (y / edit which one / skip)
```

On `y`, write each one. On `edit X`, ask the user for the correction. On `skip`, abort.

### 6. Commit

One commit covering all doc changes:

```bash
git add WORKLOG.md TODO.md CONTEXT.md   # etc., only changed files
git commit -m "docs: catch up after <one-line session topic>"
```

Do NOT push without explicit approval. This skill commits; pushing (especially to a deploy branch that auto-builds) is a separate decision the user makes.

## Common mistakes

- **Padding WORKLOG with trivia.** One paragraph per session, summarizing the arc. The git log has the detail. Don't restate every commit message in prose.
- **Decision-record inflation.** "We chose X over Y" is a decision IF Y was a real alternative and the cost of reversing is real. Most refactors don't warrant a record.
- **General programming terms in CONTEXT.md.** "Timeout" is not domain vocabulary. "Bundle" (when your system has a specific Bundle concept) is.
- **Duplicating content across files.** WORKLOG is the diary, DECISIONS is the why, ARCHITECTURE is the shape, CONTEXT is the vocabulary, README is operator-facing, CLAUDE is agent-facing. They reinforce, they don't repeat.
- **Pushing without approval.** `git push` to a deploy branch is a separate ask. This skill commits; deploy-decisions are the user's.

## Red flags (stop and reconsider)

- About to write more than one paragraph to WORKLOG. Probably padding. Trim.
- About to add a 5-bullet decision record. Probably belongs as a single line in WORKLOG or a single bullet in TODO instead.
- About to mention "Claude" or "agent" in WORKLOG. The diary is for humans; agent learnings go to a memory system.
- About to add CLAUDE.md entries that overlap with an existing memory entry. Memory is the right home for cross-repo learnings.

## Quick reference

```
docs-update flow:
  inventory  →  read each  →  survey delta  →  per-doc decide
                                                      ↓
                                                  preview
                                                      ↓
                                                  user: y
                                                      ↓
                                                  write + commit
                                                  (no push)
```

Related:
- The `context-md` skill: CONTEXT.md format and the glossary-maintenance worker docs-update delegates to.
- Continuous-diary cadence: append WORKLOG entries as work happens, not batched at session end.
