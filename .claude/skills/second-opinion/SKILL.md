---
name: second-opinion
description: Heterogeneous-model code review of the current branch's changes. Invokes GitHub Copilot CLI with gpt-5.3-codex to review git diff since merge-base with the repo's trunk branch (or user-specified commit). Reads .claude/skills/second-opinion/REVIEW-BRIEF.md for focused project context. Returns structured findings that Claude reads, summarizes, and acts on. Use when the user types `/second-opinion`, asks for a second opinion on a branch, wants GPT to review the work, or wants an independent review before pushing.
disable-model-invocation: false
---

# Second opinion

Heterogeneous-model author-time review of the current branch. Runs **GitHub Copilot CLI** (`copilot`) with a GPT-family model (default `gpt-5.3-codex`) against the diff since `git merge-base "$TRUNK_REF" HEAD`, where `$TRUNK_REF` is a resolvable git ref for the repo's default branch - either a local branch (`main`) or a remote-tracking ref (`origin/main`), resolved in Phase 1. The reviewer returns structured findings; Claude reads them and acts.

The bias-control mechanism is **the process boundary itself**. Copilot runs as a separate binary, with a separate model family, returning only text. Claude (the implementer) cannot influence Copilot's review; Copilot cannot edit code. Tool restriction inside Copilot is unnecessary - the architecture enforces the separation.

## When to use

- `/second-opinion` - review current branch vs. `git merge-base "$TRUNK_REF" HEAD` (trunk autodetected in Phase 1; works for both local and remote-only checkouts)
- `/second-opinion <commit>` - review since an arbitrary commit hash
- `/second-opinion --model <id>` - use a different Copilot model
- "Get a second opinion before I push" / "have GPT review this" - same as `/second-opinion`

## Prerequisites

`copilot` CLI installed and authenticated. Verify with `command -v copilot >/dev/null && copilot --version`. If missing, surface to the user: install via `https://gh.io/copilot-install` and run `copilot login`. Updates via `copilot update`.

## Workflow

### Phase 0 - verify review brief

Run the bundled check script to verify `REVIEW-BRIEF.md` targets this repo:

```bash
python3 <skill-path>/scripts/review_brief.py check
```

Returns JSON with `match`, `brief_repo`, `current_repo`, `needs_update`.

- **Match** → proceed to Phase 1.
- **Mismatch or missing `repo:` tag** → run discovery and offer a one-time rewrite:

  ```bash
  python3 <skill-path>/scripts/review_brief.py discover
  ```

  The discovery output includes detected stacks, context from `CLAUDE.md`/`AGENTS.md`/`README.md`, and the existing brief content. Use this context to rewrite `REVIEW-BRIEF.md` with:
  - Updated `repo:` frontmatter tag matching the current repo
  - Project description derived from the discovered context
  - Focus areas appropriate for the detected tech stack
  - Empty "Known patterns - do NOT flag" section (compounding loop will fill it)
  - Same output format and bias-control rules (these are repo-agnostic)

  Present the rewrite to the user via `AskUserQuestion` ("Update REVIEW-BRIEF.md for this repo?"). On approval, write the file. On decline, proceed with the existing brief (it may produce noisy or irrelevant findings).

This phase runs once per repo. After the brief is updated, `check` returns `match: true` on all subsequent runs.

### Phase 1 - resolve the diff base

This skill is portable across repos that use `main`, `master`, `trunk`, `prod`, etc. - never assume `main`. Resolve `$TRUNK_REF` to a git ref that's guaranteed to exist locally (a local branch OR a remote-tracking ref - many CI environments only have the trunk at `refs/remotes/origin/<name>`), then merge-base against it:

```bash
# Detect the trunk name (zero-network first, then fallbacks)
TRUNK_NAME=""
ref="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)" && TRUNK_NAME="${ref#origin/}"
[ -n "$TRUNK_NAME" ] || TRUNK_NAME="$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null)"
[ -n "$TRUNK_NAME" ] || for c in main master trunk prod; do
  git show-ref --verify --quiet "refs/heads/$c" && TRUNK_NAME="$c" && break
  git show-ref --verify --quiet "refs/remotes/origin/$c" && TRUNK_NAME="$c" && break
done
[ -n "$TRUNK_NAME" ] || { echo "Could not resolve trunk; run: git remote set-head origin -a" >&2; exit 1; }

# Resolve to a usable git ref (prefer local branch, fall back to remote)
if git show-ref --verify --quiet "refs/heads/$TRUNK_NAME"; then
  TRUNK_REF="$TRUNK_NAME"
elif git show-ref --verify --quiet "refs/remotes/origin/$TRUNK_NAME"; then
  TRUNK_REF="origin/$TRUNK_NAME"
else
  echo "Trunk '$TRUNK_NAME' has no local or remote ref; run: git fetch origin $TRUNK_NAME" >&2; exit 1
fi

# Default: merge-base with trunk
base="$(git merge-base "$TRUNK_REF" HEAD)"

# Alternative: a user-specified commit from skill args overrides the default.
# Uncomment and substitute when the caller passed an explicit base ref:
# base="<user-arg>"
```

Each fallback is gated on the previous one having actually produced a value - **never collapse the `symbolic-ref` step into a `git symbolic-ref ... | sed ...` pipeline**, because `sed` always exits 0 even when the upstream `git symbolic-ref` failed, so the `||` chain wouldn't trigger. The block always re-resolves `TRUNK_REF` from scratch every time it runs - it does not check for or respect a pre-existing `$TRUNK_REF` in the environment. If a caller has already resolved trunk, the re-resolution returns the same value (so re-running is safe and produces no surprises), but it does *run* every time; it's not skipped.

If `base == HEAD`, exit early: "Nothing to review - branch is at parity with the base." Don't invoke Copilot.

**Caller contract: review scope is committed state only.** Uncommitted working-tree changes are invisible to `git diff <base>..HEAD` and therefore invisible to the reviewer. Callers that need to review uncommitted work (a branch with WIP in the working tree but no commits ahead of the base) must create a throwaway WIP commit *before* invoking this skill, then dispose of it after via their own flow (e.g., `git reset --soft <base>`). This skill will not silently degrade by reviewing the working tree - the process boundary that gives Copilot its bias-control also means it only sees what `git` shows it.

### Phase 2 - invoke Copilot

Single Bash call. The prompt tells Copilot to read the brief, run `git diff` itself, and produce findings in the brief's specified format:

```bash
copilot -p "Read .claude/skills/second-opinion/REVIEW-BRIEF.md, then review the current branch's changes since <base>. Run: git diff <base>..HEAD to see all changes. Read referenced files for context as needed. Output findings using the format and severities specified in the brief." \
  -s \
  --model gpt-5.3-codex \
  --no-custom-instructions \
  --allow-all-tools
```

Flag rationale:

- **`-s`** (silent) - strips UI chrome, leaves only the agent's response on stdout. Critical for parsing.
- **`--no-custom-instructions`** - skips `AGENTS.md` and `.claude/skills/` auto-loading. The curated `REVIEW-BRIEF.md` is the only context Copilot needs. Loading everything would burn attention budget on irrelevant context.
- **`--allow-all-tools`** - required for non-interactive `-p` mode. Safe here: Copilot's output is text-only back to Claude; any edits Copilot might attempt happen in its process, not Claude's. Even if Copilot wrote a file, Claude would not act on it - Claude only acts on the findings text.
- **`--model gpt-5.3-codex`** - default. Override via skill arg (see model override below).

If Copilot exits non-zero, capture the error and surface to the user. Don't retry automatically.

### Phase 3 - parse and act on findings

Save Copilot's raw output to a temp file and parse it with the bundled script:

```bash
python3 <skill-path>/scripts/review_brief.py parse /tmp/copilot-review.md
```

Returns JSON: `{"findings": [{id, severity, file, line, description, suggestion}, ...], "count": N}`. If count is 0, announce "No findings." and exit.

#### Output handling

Two modes, selected by the caller via context (the skill itself doesn't need to know who called it):

**Interactive mode** (default - standalone `/second-opinion`):

1. Present a summary table to the user:

   ```text
   ## Copilot review (gpt-5.3-codex) - 3 findings

   | ID | Severity | Location | Summary |
   |----|----------|----------|---------|
   | F-001 | bug | src/main.py:142 | <one-line> |
   | F-002 | warning | lib/utils.sh:88 | <one-line> |
   | F-003 | nit | docs/index.md:23 | <one-line> |
   ```

2. Ask via `AskUserQuestion` which to act on. For ≤4 findings, use one question with multiSelect options (`F-001`, `F-002`, ...). For more, present in chunks of 4 or ask "fix all bugs, triage warnings/nits?" first.
3. For each finding the user wants fixed: Claude reads the relevant file, formulates a fix from Copilot's `Suggestion`, applies it via `Edit`. **Do not copy Copilot's patch verbatim** - Copilot suggests direction; Claude writes the actual edit using its own knowledge of the codebase.
4. After edits, run `make lint` to validate.

**Automated mode** (when invoked by another skill as a pre-push review gate):

1. Auto-fix findings with `severity: bug` AND a concrete `Suggestion` that maps cleanly to one or two lines of code. No user prompt needed for these - they're obvious corrections.
2. Surface to the user via `AskUserQuestion`:
   - Any `bug` finding where the fix is non-obvious or spans multiple files.
   - All `warning` findings (by definition, judgment is needed).
   - `nit` findings only if the user explicitly opted in (default: skip nits - they're not blockers).
3. After resolution, re-run `make lint` to validate.
4. Return control to the caller. Review-driven fixes are uncommitted working-tree changes - the caller decides how to commit them.

The caller selects automated mode by passing findings context (e.g., "act on findings per automated mode"). Without that context, the skill defaults to interactive mode.

## Model override

Pass `--model <id>` in the skill args. Claude extracts it and substitutes for `gpt-5.3-codex` in the Copilot invocation.

Currently available Copilot models (May 2026 - list with `copilot -p "list available models"`):

| Model ID          | Tier       | Notes                                                                                                                              |
| ----------------- | ---------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| `gpt-5.3-codex`   | standard   | **Default** - code-focused, balanced cost                                                                                          |
| `gpt-5.2-codex`   | standard   | Older codex; use only if 5.3 unavailable                                                                                           |
| `gpt-5.5`         | premium    | Heavier; use for complex / security-sensitive diffs                                                                                |
| `gpt-5.4`         | standard   | General-purpose; less code-specialized than codex variants                                                                         |
| `gpt-5-mini`      | fast/cheap | Quick triage; expect more noise / missed nuance                                                                                    |
| `claude-opus-4-7` | premium    | **NOT heterogeneous** - same family as Claude (the implementer); only useful if you specifically want a same-family second context |

## Anti-patterns

- **Running `/second-opinion` repeatedly on the same diff.** Wastes Copilot API tokens. If the first run missed something, evolve `REVIEW-BRIEF.md` (add a focus area), don't re-run.
- **Dropping `--no-custom-instructions`.** Copilot would auto-load `AGENTS.md` and every file under `.claude/skills/`. That's hundreds of lines of context unrelated to the actual diff review.
- **Piping the full diff into the `-p` argument.** Copilot's shell access lets it run `git diff` itself - piping risks shell-escape issues and prompt-size limits. Let Copilot run the command.
- **Copying Copilot's patch verbatim.** Copilot's `Suggestion` is a direction; Claude writes the actual edit. Verbatim copies skip Claude's knowledge of the codebase's idiomatic patterns and accepted decisions.
- **Adding `Co-Authored-By: Copilot` to fix commits.** Fixes derived from Copilot's review are Claude's edits informed by Copilot's review - same as a human reviewer's comment. No tooling attribution needed.
- **Running `/second-opinion` after a destructive history rewrite (soft-reset).** Review-driven fixes after a soft-reset need a second reset cycle to re-cut clean commits. Run the review *before* any history rewrite so fixes land in the WIP state and get consolidated for free.

## Example invocations

- `/second-opinion` - review against `git merge-base "$TRUNK_REF" HEAD` (trunk autodetected in Phase 1; works for both local and remote-only checkouts)
- `/second-opinion abc1234` - review against an arbitrary commit
- `/second-opinion --model gpt-5.5` - use a heavier model for a security-sensitive branch
- "Get a second opinion before I push" - same as `/second-opinion`

## Compounding loop

`REVIEW-BRIEF.md` is **git-tracked** so it compounds across runs. Two triggers update it:

1. **Copilot keeps flagging an intentional pattern** → add it to the "do NOT flag" section.
2. **Copilot misses a class of bug repeatedly** → add the relevant focus area or paired-file mapping.
