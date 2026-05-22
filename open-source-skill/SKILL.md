---
name: open-source-skill
description: Use when you point at an internal markdown artifact (a Claude Code skill, slash command, prompt template, or hook README) and ask to "open source this," "publish publicly," "share with friends," "turn into a lead magnet," "make a public repo," "fork for the community," or "put on GitHub." Same flow whether destination is a discoverable public repo or an email-gated lead magnet. Skip for npm packages (use alexknowshtml/claude-skills publish-oss instead) and for inbound external content you want to absorb into your own system.
---

# open-source-skill

Take an internal markdown artifact you've built (a skill, command, prompt template, hook README) and ship a public, shareable version of it. Output is a small standalone GitHub repo a stranger can clone and use.

The whole point: private-to-public is mostly a **scrub** task, not a write task. The artifact is good; what needs work is stripping the parts that only make sense inside your setup (dead cross-refs, paired-skill references, internal tracker IDs, personal names, private path examples).

## Companion skill, not duplicate

For TypeScript/JS packages that publish to npm, use [`alexknowshtml/claude-skills/publish-oss`](https://github.com/alexknowshtml/claude-skills/blob/main/publish-oss/SKILL.md) instead. That skill covers monorepo subtree pushes, dist builds, version bumps, and `npm publish` with granular tokens. This skill covers the markdown-artifact case where there's no build step and no npm.

## When to use

- You gesture at a specific markdown artifact and want to publish / share / fork it
- Building a lead magnet whose deliverable is a skill or command repo
- A skill someone asked you to share, and the easiest answer is "here's a repo"

## When NOT to use

- The artifact has nothing personal in it. Push it as-is.
- One-line gist / pasted snippet. No repo scaffold needed.
- npm package: use Alex's `publish-oss`.
- Inbound direction (absorbing an external skill into your own system): use a different flow.
- The artifact depends on private infrastructure (custom daemons, scoring systems, scheduled prompts, sync scripts) such that no scrub makes it standalone. Reconsider scope before publishing.

## Process

### Step 1: Three upfront decisions (one prompt, before building)

1. **Scope.** Single artifact, or paired bundle? If the artifact references a sibling (e.g. one skill delegates to another), shipping just one leaves a dangling reference. Recommend the bundle unless explicitly told otherwise.
2. **Scrub level.** Full generalize / light touch / verbatim. Recommend full. Verbatim ships dead refs.
3. **Destination and gate.** Three patterns:
   - **Public-and-discoverable:** `gh repo create --public`, no opt-in
   - **Lead magnet via email gate:** same public repo, README ends with an email-tool opt-in (Bento, ConvertKit, etc.); the repo URL only goes out via the email sequence
   - **Local build, you push:** build, no `gh repo create` from the agent. Safest default if unsure.

Default to "local build, you push" for outward action until you explicitly authorize the push.

### Step 2: Credential and dependency check

```bash
gh auth status 2>&1 | grep -E "Logged in|account" | head -3

# What does the artifact reference?
grep -nE '\[\[[a-z0-9_-]+\]\]|`[a-z0-9_-]+\.md`|/Users/[^/]+/|~/[a-zA-Z0-9_-]+/' <artifact-file>

# What references the artifact back? (don't break internal callers)
grep -rln '<artifact-name>' ~/.claude/skills/ ~/.claude/commands/ .claude/skills/ .claude/commands/ 2>/dev/null
```

First command verifies push is possible. Second is the scrub target list. Third surfaces internal cross-refs you'd break by renaming.

### Step 3: Scaffold

Standard layout for a single-skill repo (paired bundle just adds a sibling under `skills/`):

```
<repo-name>/                     # at ~/Projects/, NOT inside any auto-syncing dir
├── README.md
├── LICENSE                      # MIT unless you have a reason otherwise
├── .gitignore                   # at minimum: .DS_Store
└── skills/<skill-name>/SKILL.md
```

If you have any auto-commit cron, build OUTSIDE its scope. Otherwise the cron will try to track the new repo as part of your main repo.

### Step 4: Scrub (the core of this skill)

Pass each file through this scan, then rewrite each hit. **Six categories:**

| # | Category | Replace with |
|---|---|---|
| 1 | Personal identity (your name, email, `/Users/<you>/` paths) | `you` / `the user` / `~/` |
| 2 | Internal tracker IDs (Linear `DD-xxx`, Jira tickets, Notion DB refs) | drop |
| 3 | Dangling memory or rule cross-refs (`feedback_*.md`, `protocol_*.md`, `reference_*.md`, `[[name]]` graph links) | inline the substance or drop |
| 4 | Paired-skill references that won't be shipped | bundle the pair, OR rewrite the reference so it doesn't dangle |
| 5 | Internal project / hostname examples (your private repo names, host aliases) | neutral placeholder or drop |
| 6 | Description-field naming you specifically (`Triggers on <name> saying X`) | `Triggers on the user saying X`; the description IS the trigger, must work for installers |

One scan command catches most of it (replace `<your-name>` with your name and `<private-repo>` with the names of your private repos):

```bash
grep -rnE '<your-name>|<private-repo>|DD-[0-9]+|/Users/<you>|feedback_[a-z_]+|protocol_[a-z_]+|reference_[a-z_]+|\[\[[a-z_-]+\]\]' <repo-dir>
```

Zero hits at the end = clean. Run it twice: once after the obvious pass, once after the subtle pass. The subtle pass catches framing narrower than the skill's real scope (e.g. "coding session" when the skill applies to any work session) and personal style rules (em-dash conventions, lowercase-only) that don't transfer to readers.

### Step 5: Verify publicly installable references (lifted from Alex's publish-oss)

Extract every CLI tool, install command, or external dependency referenced in the public README / SKILL.md:

```bash
grep -hoE '`[a-z][a-z0-9-]+`|npm install [a-z0-9@/-]+|brew install [a-z0-9-]+' <repo-dir>/*.md <repo-dir>/skills/*/SKILL.md | sort -u
```

For each match, confirm it's installable from a public registry (npm, brew, apt, official download). Flag any that are internal-only.

### Step 6: README and LICENSE

**README structure** (short, scanner-friendly):

1. Title + one-paragraph what-it-is
2. What you get (bullet list; if a bundle, why they're paired)
3. Install (`cp -r skills/<name> ~/.claude/skills/`)
4. Use (slash invocation + 2-3 natural-language trigger examples)
5. Credit (upstream attribution if the artifact was lifted from someone else)
6. License (one line)

For the lead-magnet variant, insert one CTA between sections 4 and 5: *"Want updates when I release more skills? Subscribe at <url>."* Same artifact, just a soft conversion.

**LICENSE:** MIT, with your name and current year, unless you have a reason to pick something else.

### Step 7: Quality pass before commit

1. **Stranger read-through.** Read each file as if you've never seen the author's setup. Anything that dangles is a missed scrub.
2. **Re-grep.** Step 4's scan command should return zero hits.
3. **Trigger sanity.** Read the frontmatter `description:` field as a stranger. Would it trigger correctly for them? If your name survived, fix it.
4. **Local hooks may fire** even outside your usual repo (style-enforcement, branch-first guards). Respect them; don't bypass.
5. **Branch-first if working on `main`** in the new repo. `git checkout -b feat/initial`, edit, `git merge --squash` back. Many local hook setups require it.

### Step 8: Commit and push (only on explicit approval)

Build local first, even if you pre-authorized "create and push." Show the tree and final files. Wait for an explicit go-ahead, because pushing creates a public, indexable artifact.

```bash
cd ~/Projects/<repo-name>
git init -q && git add -A
git commit -m "Initial commit: <one-line>"

# Only on explicit go-ahead:
gh repo create <repo-name> --public --source . --remote origin --push \
  --description "<one-liner>"
```

## Lead-magnet variant (5-line summary)

- Repo is technically public on GitHub (cheap to host)
- Repo URL goes out only via an email-tool sequence triggered by an opt-in form
- Add a "you found this through <opt-in name>" line in the README so it reads as a deliverable
- An optional welcome sequence shipped alongside is **out of scope here** (capture as a follow-up)
- For paid/gated tarball: out of scope, that's a different skill

## Common gotchas

- Building inside an auto-syncing dir: the sync will try to commit your new repo. Build at `~/Projects/<repo-name>/`.
- Renaming inconsistently (dir / `name:` frontmatter / `# heading` / slash invocation / cross-refs all need to move together). Grep first, replace second, grep again.
- Forgot the paired skill: dangling reference for the stranger. Either bundle the pair or rewrite the ref.
- Personal name survives in the `description:` field: skill won't trigger correctly for the installer.
- `.DS_Store` snuck into the initial commit: always add `.gitignore` before `git add -A`.
- Pushed without explicit approval: outward-facing, wait for the go-ahead.

## Quick reference

```
upfront decisions  →  credential + dep check  →  scaffold ~/Projects/
                                                       ↓
                                                  scrub (6 categories)
                                                       ↓
                                                  verify publicly installable
                                                       ↓
                                                  README + LICENSE
                                                       ↓
                                                  quality pass + re-grep
                                                       ↓
                                                  commit, wait for go
                                                       ↓
                                                  gh repo create --public --push
```

## Related

- [`alexknowshtml/claude-skills/publish-oss`](https://github.com/alexknowshtml/claude-skills): npm-package companion (different artifact type, same family). Use that for TypeScript/JS publishing. Several patterns in this skill (publicly-installable check, common-gotchas section, credential pre-check) are lifted from it.
