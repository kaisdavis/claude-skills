---
name: context-md
description: Use when initializing, updating, or auditing a per-repo CONTEXT.md glossary, the ubiquitous-language / domain-vocabulary layer for a project. Triggers on "create a CONTEXT.md", "set up the glossary", "what's our vocabulary here", "what do we call X", "add X to the glossary", "audit our CONTEXT.md", "ubiquitous language", "lock down terminology", or naming the file by short ref ("CONTEXT", "the glossary", "the domain doc", "our project language"). Also fires mid-session when 3+ domain terms get resolved in a repo lacking a glossary, when a terminology debate surfaces ("Customer vs User?", "Order vs Purchase?", "should we call this X or Y?"), or when about to bail with "I don't know what we call this here." Skip for one-shot scripts, content-only repos, throwaway prototypes, and repos with fewer than 3 domain terms worth defining.
---

# context-md

Bootstrap and maintain a per-repo `CONTEXT.md` glossary. The durable home for a project's ubiquitous language.

The whole point: every session stops re-deriving domain terms from class names and inference. CONTEXT.md is canonical.

## When to fire

- User says: "create a CONTEXT.md", "set up the glossary", "what's our vocabulary here", "what do we call X", "add X to the glossary", "audit our CONTEXT.md", "ubiquitous language", "lock down terminology"
- User refers to the artifact by short name: "the glossary", "the domain doc", "our project language", just "CONTEXT"
- Mid-session: 3+ domain terms got resolved in conversation and the repo has no CONTEXT.md (offer to start one)
- Mid-session: terminology debate surfaces ("Customer vs User?", "Order vs Purchase?", "should we call this X or Y?"). The glossary is the resolution surface.
- Failure-mode: about to bail with "I don't know what we call this here", "the project uses both X and Y", or "the code is inconsistent on the term for X"
- Session start: working in a multi-session repo where no CONTEXT.md exists and the work is non-trivial (offer to start one)
- Cross-skill: another skill says "use the project's domain glossary vocabulary" but no glossary exists (offer to start one)

## When to skip

- Content-only repos (no domain logic to glossarize)
- One-shot scripts under 50 lines
- Throwaway prototypes (capture the answer elsewhere)
- Repos with fewer than 3 domain terms worth defining

## Modes

### Mode 1: `init` (bootstrap a new CONTEXT.md)

1. **Detect bounded contexts.** Walk the repo tree. If it splits cleanly into multiple domains, propose a `CONTEXT-MAP.md` plus per-context files. Otherwise single root `CONTEXT.md`.

2. **Scan code for likely domain terms.** Look at:
   - Class names (especially those that aren't framework primitives)
   - Repeated nouns in route names, controller actions, model relationships
   - Service-class names and their public methods
   - Database table names and column names that aren't generic (id, created_at, etc.)
   - Test descriptions ("user can checkout with...")
   - String literals in prompts (for LLM-feature repos)

3. **Interview the user on candidates.** Present a numbered list of 15 to 25 candidate terms. For each:
   - Is this domain-specific or general programming? (Drop general.)
   - Is the name correct or should it be renamed? (Capture in `_Avoid_:`.)
   - Are there synonyms used elsewhere that should be aliased away?

   Ask one cluster at a time. Don't dump all 25 at once.

4. **Draft v1.** Write the file in the canonical format (see the source-of-truth template linked under Cross-refs):
   - One or two sentence preamble
   - `## Language` section with bolded terms, tight definitions, and `_Avoid_:` aliases
   - `## Relationships` with cardinality
   - `## Flagged ambiguities` (start empty if none surfaced)
   - `## Example dialogue` between dev and domain expert (invent if needed; must read naturally)

5. **Multi-context only:** also write `CONTEXT-MAP.md` listing contexts plus relationships between them. Each per-context file gets its own `CONTEXT.md` with the same internal structure.

6. **Commit on a feature branch.** Don't write to main directly on shared repos.

### Mode 2: `update` (add/sharpen a term mid-session)

Triggered when a domain term gets resolved in conversation. Do this **inline**, not batched at session end.

1. Read current CONTEXT.md.
2. Locate the right section (Language for new term, Relationships for new cardinality, Flagged ambiguities for resolved conflict).
3. Add the entry verbatim in the canonical format.
4. If the new term conflicts with existing usage in code, surface it: "your code uses `Account` here, but CONTEXT.md just resolved this to `Customer`. Want me to flag the conflict in Flagged ambiguities and leave the rename for later, or rename now?"
5. Commit as a tiny atomic change (or stash for end-of-session bundle if mid-feature).

### Mode 3: `audit` (check existing CONTEXT.md against code)

Triggered by "audit our CONTEXT.md", "is our glossary still accurate", or after a major refactor.

1. Read CONTEXT.md.
2. For each `**Term**:` in `## Language`, grep the codebase for occurrences. If zero hits, term is dead. Propose removal.
3. For each `_Avoid_:` alias, grep for occurrences of the avoided term. If hits exist, surface them. Code uses banned terminology, candidate for rename or for moving the alias to canonical.
4. Scan code for nouns NOT in CONTEXT.md that appear 5+ times across 3+ files. Candidates for addition.
5. Present a numbered diff: terms to add, terms to remove, aliases to enforce. User approves; apply.

## The five discipline rules

1. **Be opinionated.** Pick one canonical term; others become `_Avoid_:`.
2. **Inline updates, not batched.** Resolved during conversation, updated in the file before the next turn moves on.
3. **Selectivity.** Project-specific terms only. Drop general programming concepts.
4. **Definitions are tight.** One sentence. Define what it IS, not what it does.
5. **Flag conflicts explicitly.** Ambiguous terms get a `## Flagged ambiguities` entry with resolution.

## Cross-skill plumbing

Once CONTEXT.md exists, other skills can reference it as the canonical vocabulary source. Examples: a module-map / "zoom out" skill, a debugging skill's mental-model orientation, a TDD skill (test names and interface vocabulary match CONTEXT.md), and a PRD skill (uses CONTEXT.md vocabulary in the PRD body). The pattern: domain vocab comes from CONTEXT.md; architecture/tooling rules live in a separate house-style doc.

## Anti-patterns to avoid

- **Don't scaffold an empty CONTEXT.md.** Lazy-create when the first term resolves.
- **Don't batch terminology updates to end-of-session.** Inline is the discipline.
- **Don't include general programming terms.** "Timeout", "retry", "cache" don't belong unless the project gives them domain meaning.
- **Don't lose `_Avoid_:` to politeness.** Pick a canonical winner; surface losers as aliases.
- **Don't define what a term does.** Define what it IS. Behavior belongs in code.

## Cross-refs

- Source / format template: the `grill-with-docs` skill in [mattpocock/skills](https://github.com/mattpocock/skills). See `skills/engineering/grill-with-docs/CONTEXT-FORMAT.md` for the source-of-truth CONTEXT.md format.
- Companion: the `docs-update` skill delegates CONTEXT.md edits to this skill during an end-of-session doc catch-up.
