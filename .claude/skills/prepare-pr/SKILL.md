---
name: prepare-pr
description: Wrap a feature branch up into a clean, shippable PR - consolidate WIP commits into a small set of Conventional Commits by prefix (feat/fix/chore/docs/test/refactor), run `make lint-diff` once at the end, push, then create or update a descriptive PR. Skips per-commit hooks via `--no-verify` and runs them in one pass after consolidation. Use when the user types `/prepare-pr`, says "wrap this branch up", "ship this branch", "open a PR for this", "consolidate the commits and PR", or similar end-of-branch language. Disabled for auto-invocation.
disable-model-invocation: true
---

# Prepare PR

End-of-branch consolidation skill for this repo. Take a branch with ad-hoc WIP commits + lint side-effects accumulated during development, regroup the file-level changes by Conventional Commits prefix, run lint once, push, and open or update a descriptive PR.

This repo ships versioned tooling - several PowerShell modules under `modules/`, each with a `ModuleVersion` in its `modules/<name>/<name>.psd1` manifest (`do-common`, `do-unix`, `do-az`, `utils-install`, `utils-setup`, `psm-windows`, `aliases-git`, `aliases-kubectl`) - but it does not gate releases on a CHANGELOG or automated SemVer arithmetic, so this skill takes no version-bump argument. If a change warrants a module version bump, that's an explicit edit the author makes in the relevant commit; the skill just produces clean commits and a clear PR. (There is no Python/npm package here - no `pyproject.toml`/`package.json` - so the only versioned artifacts are the `.psd1` manifests.)

## When to use

- `/prepare-pr` - run the full pipeline against the current branch
- `/prepare-pr --skip-review` - skip Phase 1.5 (`/second-opinion`) and Phase 4.5 (`/address-pr-review`); use when Copilot is offline, or when you've already run both skills manually earlier in the session
- "wrap this branch up" / "ship this branch" / "open a PR for this" - same flow
- "update the PR with the new commits" - re-run; history rewritten + force-pushed, PR body updated

## Workflow

Four numbered phases plus two interstitials (Phase 1.5 heterogeneous-model review, Phase 4.5 PR review address). Stop and surface the error if any phase fails - do not paper over.

### Phase 1: Survey and categorize

Get the lay of the land *before* proposing any changes to history.

1. **Sync the local trunk.** Run this **first**, before anything else touches the trunk - every later merge-base, diff, and lint compares against it, and a stale local trunk silently poisons all of them (a stale local `main` inflated the branch's `main..HEAD` from 15 to 33 commits in one real run, and would have made the Phase 2 soft-reset revert already-merged commits). `sync-trunk` fetches origin and fast-forwards the local trunk ref if it is behind - it never checks out trunk (the working tree is untouched; it moves the ref with `git update-ref`), so it's safe to run from the feature branch.

   ```bash
   uv run --frozen python .claude/skills/prepare-pr/scripts/extract_signals.py sync-trunk
   ```

   Read the JSON `action`:
   - `up-to-date` / `fast-forwarded` / `no-local` / `no-origin` → proceed.
   - `offline` (fetch failed) → non-fatal; announce it and proceed (origin/local refs are whatever's on disk). The `--force-with-lease` in Phase 4 is the backstop.
   - `diverged` (exit 1) → **stop.** The local trunk has commits not on origin - a broken state a fast-forward can't resolve (fast-forwards never conflict; divergence means real local commits). Surface the JSON `reason` and tell the user to reconcile (`git checkout <trunk> && git pull --ff-only`, or investigate the local commits) before re-running.

   This also fixes a repo-local footgun: this repo's `make lint-diff` hard-codes `--from-ref main` (the **local** ref), so without this step Phase 3's lint validates against a stale base too.

2. **Detect the trunk branch.** This skill is a gallery item portable across repos - never assume `main`. The bundled `extract_signals.py` script resolves trunk via the fallback chain `git symbolic-ref refs/remotes/origin/HEAD` → `gh repo view --json defaultBranchRef` → probe `main`/`master`/`trunk`/`prod` against both local and remote refs. Each downstream subcommand auto-resolves trunk internally; only the agent-facing display below needs separate calls:

   - **`trunk-name`** - prints the bare branch name (`main`, `master`, ...). Pass this literal to `gh pr create --base <name>`.
   - **`trunk-ref`** - prints a fully-resolvable git ref (`origin/main` when a remote-tracking ref exists, else the local `main` branch). Pass this literal to `git log <ref>..HEAD`, `git diff <ref>..HEAD`, `git merge-base <ref> HEAD`, etc. It prefers `origin/<name>` because that's authoritative - it's what the PR is computed against and stays current on fetch, whereas a local trunk branch often lags in a feature-branch workflow and would make every merge-base resolve too far back (pulling already-merged commits into the diff/reset). Run `git fetch` first so `origin/<name>` is current. Many CI environments only have trunk at `refs/remotes/origin/<name>`, so plain `main` would fail there anyway.

   ```bash
   uv run --frozen python .claude/skills/prepare-pr/scripts/extract_signals.py trunk-name
   uv run --frozen python .claude/skills/prepare-pr/scripts/extract_signals.py trunk-ref
   ```

   Substitute the printed values as **literal arguments** in subsequent commands - never `$VAR` interpolation, since shell variables don't persist across the agent's separate `Bash` tool calls. For example, if `trunk-ref` prints `main`, the next call is literally `git log --oneline main..HEAD`; if it prints `origin/main`, the next call is literally `git log --oneline origin/main..HEAD`. Sticking to plain commands (no `eval`, no `$(...)` substitution) keeps every `Bash` invocation statically analyzable by the permission matcher, so they don't trigger approval prompts.

   Non-zero exit + stderr message means trunk resolution failed - the typical remedy is `git remote set-head origin -a` (or `git fetch origin <trunk>` if the trunk's ref isn't available locally at all). Surface the error verbatim; silent misdetection is worse than a noisy abort. The script is bundled because the bash version of this chain has two famous footguns caught in PR review: `git symbolic-ref ... | sed ...` masks failures (the upstream `git symbolic-ref` exit code gets shadowed by `sed`'s always-zero exit), and the local-only `for c in ... do git show-ref refs/heads/$c` probe misses CI checkouts where trunk is only at `refs/remotes/origin/<name>`.

3. **Verify the branch is safe to rewrite.** Run `extract_signals.py branch-safety` - it refuses (non-zero exit, structured JSON output) if the current branch matches the resolved trunk name, is in `{main, master, develop, trunk, prod}`, or matches `^release/`. Belt-and-suspenders matters here because a repo can have a default branch named `main` *and* a long-lived `master` you also shouldn't rewrite. The check is fail-closed: if trunk resolution itself fails, the JSON returns `safe: false` rather than letting an unguarded rewrite through. On refusal, surface the JSON's `reason` field and stop; tell the user to switch to a feature branch.

   ```bash
   uv run --frozen python .claude/skills/prepare-pr/scripts/extract_signals.py branch-safety
   ```

4. **Capture the current HEAD SHA** for emergency restore. Print it in the output so the user can `git reset --hard <SHA>` if anything goes wrong.

   ```bash
   git rev-parse HEAD
   git branch --show-current
   ```

5. **List what's changed since trunk**, plus anything uncommitted or staged (lint side-effects often live in the index). Substitute the `trunk-ref` value from step 2 as a literal in the two trunk-relative commands:

   ```bash
   git log --oneline <trunk-ref>..HEAD
   git diff --name-status <trunk-ref>..HEAD
   git diff --name-status                 # uncommitted (working tree)
   git diff --cached --name-status        # staged
   ```

6. **Read the repo's commit-convention doc before classifying.** If a project doc exists (common names: `ARCHITECTURE.md`, `AGENTS.md`, `CONTRIBUTING.md`, `CLAUDE.md`, `.github/`), skim it for commits/conventions and versioning sections. **Repo-specific rules override the generic taxonomy below.** The generic prefixes are only a fallback for repos with no documented convention - never let them override a rule the repo actually states. In particular, watch for: per-scope prefixes and any dedicated release/version-bump commit form the repo prescribes, and versioned artifacts that must be committed separately (see the grouping rule below).

7. **Classify each changed file into one Conventional Commits prefix, grouped by `(prefix, concern)` - not prefix alone:**
   - `feat` - new functionality or a new file the project didn't have
   - `fix` - bug fix; existing thing didn't work, now works
   - `chore` - tooling, build config, dependency bumps, CI, hook tweaks, gitignore
   - `docs` - vault content (`docs/**`), READMEs, design docs, skill bodies
   - `test` - new or updated tests with no production change in the same file
   - `refactor` - behavior-preserving cleanup
   - For `docs` changes inside a specific vault, scope it: `docs(networking)`, `docs(networking/icp)`, `docs(tls-certificates-kb)`. For hook changes, scope `chore(hooks)` or `fix(hooks)`. Scope helps reviewers skim.
   - **Two files sharing a prefix do NOT automatically share a commit.** A new module function and a new script that uses it are both `feat`, but if the repo separates them (see below) they are two commits. Group by the *logical change*, then apply the prefix - not the other way around.
   - **Versioned artifacts get their own commit + version bump.** If the repo versions a module or package via a manifest (e.g. a PowerShell module's `ModuleVersion`, a `pyproject.toml`/`package.json` `version`) and any file **under that artifact's root** changed, then: (a) that commit contains **only** the artifact's files - never mixed with the scripts/docs/tooling that merely consume it; (b) the version bump lives in that same commit (SemVer by the largest change - new public surface = MINOR, fix = PATCH, breaking change = MAJOR); (c) the message follows whatever release form the repo prescribes (from step 6). Files that only *use* the artifact do not trigger a bump. If the repo documents no versioning rule, skip this - don't invent version bumps a repo doesn't ask for.
   - **Bump only against *released* code - fold within-branch fixes into the commit that introduced them.** Before adding an increment, check whether the artifact code you're changing was introduced *earlier on this same branch* (still unreleased) vs. already exists on trunk. Run `git log --oneline <trunk-ref>..HEAD -- <artifact-path>` (or `git log -S '<symbol>' <trunk-ref>..HEAD`): if the code being fixed first appeared in a branch commit that itself bumped the version, the fix is part of *that* unreleased change - fold it into that commit and keep its version, do **not** stack a second increment. A branch that adds a function at vX.Y.0 and then corrects it before merge ships as a single vX.Y.0, not vX.Y.0 + vX.Y.1. Only increment when changing code that is already on trunk (already released). This is the #1 versioning mistake: treating a pre-merge correction to just-introduced code as a new SemVer release.

8. **Decide whether consolidation is worth doing.** If the existing commits on the branch are already clean (small N, conventional-commit titles, one logical change per commit, **and each commit respects the repo's separation/versioning rules from step 6-7**), skip Phase 2 entirely and jump to Phase 3. Heuristic: if the trunk-to-HEAD `git log --oneline` (from step 5) shows <= 3 commits AND each title starts with a conventional prefix AND the working tree + index are clean, consolidation adds noise rather than removing it. **But a low commit count is not sufficient** - a single commit that mixes a versioned artifact with its consumers (or bumps nothing when the versioned artifact changed) still warrants a re-cut, so inspect content, not just count. Otherwise propose the consolidation plan.

9. **Produce a categorization plan**: which files go in which commit, in which order, with a draft commit message for each. Bring it to the user via `AskUserQuestion` (or a plain prompt if a single yes/no): **approve, modify, or abort**.

   Do not execute history rewrites until the user approves. The user knows things about their work that the file diffs don't capture.

### Phase 1.5: Heterogeneous-model review (optional)

Invoke `/second-opinion` for an author-time review by a different model family (GitHub Copilot CLI with GPT) before the destructive soft-reset. The point of running here, not after Phase 2: any review-driven fixes get absorbed into the still-WIP commit history and Phase 2's per-prefix consolidation cleans them up for free. Running this after the soft-reset would require a second reset cycle to re-cut the clean commits.

1. **Skip-check.** If the user passed `--skip-review` in the slash-command args, announce the skip and proceed to Phase 2. Otherwise, run `command -v copilot >/dev/null` to verify the Copilot CLI is available. If it fails, log a warning and proceed to Phase 2 (never block the PR on Copilot CLI availability). Do NOT assume copilot is missing without running the check - it is installed at `~/.vscode-server/data/User/globalStorage/github.copilot-chat/copilotCli/copilot` in VS Code Server environments.
2. **Ensure the branch has reviewable history.** `/second-opinion` only sees committed state (`git diff <base>..HEAD`); any uncommitted work in the working tree is invisible to it. Two failure modes the preflight catches:

   - Branch at parity with trunk + dirty tree → empty review diff, "no findings" silently returned.
   - Branch ahead of trunk + dirty tree → review sees the *committed* changes but **not** the dirty work added on top.

   In both cases the fix is the same: create one throwaway WIP commit so everything is committed. `extract_signals.py preflight-wip` is **self-applying** - it inspects the tree, and if a WIP commit is needed, it stages everything and commits with `--no-verify` on its own. The agent runs **one command, unconditionally, every time**:

   ```bash
   uv run --frozen python .claude/skills/prepare-pr/scripts/extract_signals.py preflight-wip
   ```

   Stdout will be either `created-wip` (a commit was made) or `skip` (tree was already clean). Never gate this call on your own assessment of the tree state - the script's whole purpose is to make the right call so the agent can't get it wrong. **Skipping this step silently degrades the review:** the prior failure mode that motivated this design was "agent saw a tidy two-commit branch, decided manually a WIP commit wasn't needed, ran `/second-opinion`, got 'No findings' on 8 hours of new work that wasn't in any commit." If you ever find yourself reasoning about whether to run preflight, the answer is: run it.

   The preflight script uses `git status --porcelain` (not `git diff --quiet HEAD`) so that **untracked** files trip the guard too - a brand-new file on a fresh branch is the most common shape of "I have work to review but no commits yet," and `git diff` is blind to untracked paths. The internal `git add -A` is the **only** legitimate one in the whole skill - the commit is throwaway. Phase 2's merge-base soft-reset dissolves it automatically while preserving the working tree, so review-driven fixes fold into the per-prefix commits like any other WIP. No explicit teardown needed. Pass `--dry-run` only when you want to inspect the decision without acting (tests, debugging) - never in the live skill flow.
3. **Invoke the skill.** Get the merge-base SHA (the same one Phase 2 will use) and pass it as the `base` to `/second-opinion` - the diff is exactly "what the branch adds since it diverged from the trunk":

   ```bash
   uv run --frozen python .claude/skills/prepare-pr/scripts/extract_signals.py phase2-base
   ```

   The printed SHA is the value to pass as `base="<sha>"` when invoking `/second-opinion`. Sharing the same source-of-truth subcommand for Phase 1.5's review base and Phase 2's reset target guarantees both phases see the same starting point.

4. **Challenge every finding before acting.** The reviewer is a different model with no project context beyond `REVIEW-BRIEF.md`. It will flag intentional patterns, misread regex intent, and suggest "fixes" that break things. For each finding:
   - Read the flagged code and understand the author's intent (check git blame, surrounding context, ARCHITECTURE.md, comments).
   - If the finding is clearly wrong (flags a known pattern, misunderstands the regex/logic, contradicts a documented convention) - **dismiss it** and note why.
   - If the finding is clearly right (genuine bug, obvious typo, provably broken logic) - fix it.
   - If you cannot determine whether the finding is valid - **surface it to the user** via `AskUserQuestion` with the finding detail and your assessment of why it might or might not apply. Never auto-fix when uncertain.
5. **Present a summary** of all findings with your verdict for each: `fixed`, `dismissed (reason)`, or `needs-user-judgment`. The user should see what the reviewer flagged AND what you decided, not just the fixes.
6. **After fixes (if any).** Re-run `make lint` (lint stages modifications; Phase 2 will redo staging). Don't add commits for review fixes - they become part of the WIP state that Phase 2 consolidates.
7. **Verification rerun (if any fixes were applied).** Rerun `/second-opinion` scoped to only the files that were fixed - not the full branch diff. The fixed file list comes from your own context: you applied fixes via Edit in step 4, so you know exactly which files changed. Pass them as path arguments to `git diff`:

   ```bash
   copilot -p "Review ONLY these files for remaining issues: <fixed-file-list>. Run: git diff <base>..HEAD -- path/to/fixed1.py path/to/fixed2.py ..." ...
   ```

   This catches regressions from the fixes without re-reviewing the entire branch (which would repeat dismissed findings). Cap at 1 verification rerun. If the rerun finds new issues, fix them and proceed without a third pass.
8. **Proceed to Phase 1.5b.** The fixes become part of the WIP commits and get categorized into the right Conventional Commits prefix during Phase 2's consolidation.

If `/second-opinion` reports "No findings.", announce it and proceed straight to Phase 1.5b.

### Phase 1.5b: Extract learnings

Mine the WIP commit history for operational lessons before Phase 2 destroys it. The bundled script does the deterministic signal detection; the agent generalizes and writes the prose.

1. **Run the signal detector:**

   ```bash
   uv run --frozen python <skill-path>/scripts/extract_signals.py signals
   ```

   Returns JSON with `signals` (array of `{type, items}`), `next_lesson_id`, `existing_entries`, and `lessons_exists`. Signal types: `repeated_edits` (files in 3+ WIP commits), `lint_fixes` (commit messages matching lint-fix patterns), `corrections` (commits starting with "fix:", "revert:", etc.).

2. **Add review findings.** If Phase 1.5 fixed any `/second-opinion` findings (not dismissed), treat each as an additional signal. The script does not detect these - the agent knows them from Phase 1.5 context.

3. **No signals? Skip silently.** If the JSON `signals` array is empty and no review findings were fixed, proceed to Phase 1.5c. Do not create `design/lessons.md` or announce anything.

4. **Filter: only keep signals that could recur.** For each signal, ask: "Could this same mistake happen again in a different file, a different skill, or a different PR?" Drop signals where the fix is **self-enforcing** - infrastructure changes (Makefile targets, CI config, hook config, linter rules) that mechanically prevent the mistake from recurring. Those fixes live in the code; a lesson is redundant. Keep signals where the pattern could repeat in new code the agent writes in the future (e.g., "always redact env values in probe scripts" - the fix in one script doesn't prevent the same mistake in the next script).

5. **Draft candidate entries.** For each surviving signal, draft a generalized rule:

   ```markdown
   ## L-NNN - YYYY-MM-DD - short-tag

   **Source:** PR #TBD, branch `<branch-name>`

   <One-paragraph generalized rule. Not "I did X wrong" but "When doing Y, always Z because W.">

   ---
   ```

   - **Generalize.** The entry teaches a forward-looking rule, not a war story.
   - **Cap at 3 entries per PR.** If more signals fire, pick the 3 with broadest applicability.
   - **L-NNN numbering.** Use `next_lesson_id` from the script output.
   - **Deduplicate.** Compare against `existing_entries` from the script. Drop duplicates.

6. **Bootstrap or append.** If `lessons_exists` is false:

   ```bash
   mkdir -p design
   ```

   Create `design/lessons.md` with this header:

   ```markdown
   # Operational Lessons

   Generalized rules extracted from PR history by `/prepare-pr`. Each entry captures a pattern the agent learned the hard way and the rule that prevents recurrence. Reviewed in the PR diff before merge.

   ---
   ```

   Append candidate entries. If the file exists, append after the last entry.

7. **Proceed to Phase 1.5c.** The `design/lessons.md` changes are uncommitted working-tree state; Phase 2 classifies them under `docs` (or `chore` if no other docs changes exist).

### Phase 1.5c: Review ARCHITECTURE.md

The bundled script detects which architecture-doc sections may be stale based on the branch diff. **This step is config-driven and repo-agnostic:** the section→path map lives in `.claude/prepare-pr.toml` at the repo root (see "Config" below), not in the script. A repo with no config gets a clean no-op here - `stale_sections` is always empty - so the skill degrades gracefully when ported.

1. **Run the staleness checker:**

   ```bash
   uv run --frozen python <skill-path>/scripts/extract_signals.py architecture
   ```

   Returns JSON with the same keys on every path: `stale_sections` (the config's section names whose path prefixes were touched), `architecture_exists`, `architecture_doc` (the doc name from config, default `ARCHITECTURE.md`), `config_present` (whether `.claude/prepare-pr.toml` was found), and `changed_files_count`. With no config, `stale_sections` is `[]` and `config_present` is `false`.

2. **No stale sections? Skip silently.** If `stale_sections` is empty (including the no-config case), proceed to Phase 2.

3. **Update stale sections.** Read the architecture doc and update only the flagged sections. The section names are whatever the repo's `.claude/prepare-pr.toml` defines; find the matching heading in the doc and refresh it. For **this repo** the map is:
   - `host_guest_split` → § 1 (Host vs guest split) table if a script area appeared/moved under `wsl/`, `.assets/scripts/`, `.assets/provision/`, or `.assets/trigger/` (a new execution context or invocation path).
   - `hook_inventory` → § 3 (Pre-commit hook inventory) table if `.pre-commit-config.yaml` or a hook under `tests/hooks/` changed (add/remove a row, refresh the "what it checks / why").
   - `test_layout` → § 4 (Test layout) tree if the `tests/` structure changed (new subdir, new hook module, changed `make test-*` wiring).
   - `powershell_modules` → § 6 (PowerShell modules) if `modules/` gained/lost/renamed a module or `.assets/scripts/modules_update.ps1` changed - refresh the synced-vs-local table (§ 6.1), the sync list, and the install-sites table (§ 6.2). A synced-module rename (e.g. `do-linux` → `do-unix`) also touches every install site listed there.

4. **The changes join the `docs` commit in Phase 2.**

#### Config (`.claude/prepare-pr.toml`)

The staleness map and the doc/lessons paths are **per-repo config**, not baked into the bundled script - that's what keeps the script portable enough to live in `~/.claude/skills/` and be shared across repos. The script reads `.claude/prepare-pr.toml` from the git repo root; when it's absent, malformed, or `tomllib` is unavailable (Python < 3.11), every consumer falls back to a safe default (the `architecture` check becomes a no-op, `lessons_path` defaults to `design/lessons.md`). To adopt the skill in a new repo, drop a file like:

```toml
architecture_doc = "ARCHITECTURE.md"   # doc scanned for staleness (default)
lessons_path     = "design/lessons.md" # where Phase 1.5b writes lessons (default)

[architecture_sections]                # section name -> path prefixes that mark it stale
powershell_module = ["modules/"]
build_pipeline    = ["pyproject.toml", "Makefile"]
# ... one entry per architecture-doc section you want staleness-checked
```

Omit `[architecture_sections]` entirely to disable the staleness check (Phase 1.5c becomes a silent no-op) - appropriate for repos with no architecture doc.

### Phase 2: Soft-reset and recommit by (prefix, concern)

Skip entirely if Phase 1 step 8 concluded the branch is already clean.

1. **Clear the index** so we start from a known state:

   ```bash
   git restore --staged .
   ```

2. **Soft-reset to the merge-base with trunk** so all branch changes become unstaged but the working tree is preserved. Critically, target the **merge-base**, not the trunk tip - if trunk has advanced since the branch was cut and you reset to the tip, the next commits would diff against the new tip and look like they're reverting the unrelated trunk changes that happened in between:

   ```bash
   uv run --frozen python .claude/skills/prepare-pr/scripts/extract_signals.py phase2-base
   # Substitute the printed SHA as a literal in the next command:
   git reset --soft <printed-sha>
   git restore --staged .
   ```

3. **For each group from the plan**, stage explicitly and commit with `--no-verify` (we'll validate via `make lint-diff` once in Phase 3, instead of paying the per-commit hook cost N times):

   ```bash
   git add <files-for-this-group>           # explicit list, never `git add .` or `-A`
   git commit --no-verify -m "<prefix>(scope): <one-line summary>"
   ```

   Order doesn't matter for the diff but does affect reviewer cognitive load. Suggested order: `feat` → `fix` → `refactor` → `test` → `chore` → `docs`. Foundations first, ergonomics last.

4. **Commit message style** - terse, single-line, Conventional Commits. Match the project's existing style. To inspect prior commit titles for examples, run `extract_signals.py trunk-ref`, then `git log --oneline <printed-ref> | head -20` (literal substitution, not shell variable). The body is optional and only adds value when the *why* is non-obvious from the file changes - skip the body for routine work.

   Examples from this repo:
   - `feat(docs): publish tls-certificates-kb vault to mkdocs site`
   - `docs(networking/icp): align with official ICP documentation`
   - `fix(hooks): handle hidden directories in cspell ignorePaths`
   - `chore(hooks): patch align_tables.py to respect '|' inside wikilinks`

5. **Never use `git add .` or `git add -A`** in this phase. The active scope is what *you* want in each commit, not whatever happens to be in the working tree. Always explicit file lists.

### Phase 3: Final lint

Per-commit hooks were skipped via `--no-verify`; this is where we validate the consolidated state.

```bash
make lint-diff
```

Use `make lint-diff` (not `make lint`) - post-commit there are no uncommitted changes for `make lint` to operate on; `make lint-diff` runs hooks against the diff to trunk, which is what we actually want to validate. Per-repo note: the Makefile target itself may hard-code its trunk ref (this repo's does, against `main`) - if you port this skill to a repo where the Makefile uses a different trunk name, the target needs updating too, separately from this skill.

- **Passes + working tree clean** → done; proceed to Phase 4.
- **Passes + files modified by auto-fix hooks** (whitespace, table alignment, EOF, formatter side-effects) → amend the relevant commit:

  ```bash
  git commit --amend --no-verify --no-edit -a
  ```

  Acceptable noise - the auto-fix output is uniform across hooks and doesn't change meaning. If the auto-fix touched files that conceptually belong to a different prefix than the last commit, split the fixup into a fresh `chore: lint fixups` commit instead of amending.
- **Fails non-recoverably** → stop. Surface the error. Do not push. The user fixes manually, then re-runs Phase 3 + 4.

If `mkdocs build --strict` is part of the project's quality gate (it is, for vault changes), run `uv run mkdocs build --strict` as well and surface any warnings - strict-mode warnings fail the build.

### Phase 4: Push and PR

1. **Push.** If the branch has no upstream yet:

   ```bash
   git push -u origin <branch>
   ```

   Otherwise (history was rewritten):

   ```bash
   git push --force-with-lease
   ```

   `--force-with-lease` (not bare `--force`) refuses to clobber remote commits you haven't seen - safety net for the "someone else pushed in the last 5 minutes" case.

2. **Create or update PR.** Probe first:

   ```bash
   gh pr view --json number,title,body 2>/dev/null
   ```

   - **No PR** → create. Get the trunk name as a literal (no shell variables):

     ```bash
     uv run --frozen python .claude/skills/prepare-pr/scripts/extract_signals.py trunk-name
     # Substitute the printed name as a literal in the next command:
     gh pr create --base <printed-name> \
       --title "<prefix>(scope): <descriptive title>" \
       --body "$(cat <<'EOF'
     ## Summary

     - <bullet per logical change, derived from the consolidated commits>
     - <...>

     ## Test plan

     - [x] `make lint` - all 12 pre-commit hooks green
     - [x] `uv run mkdocs build --strict` - zero warnings (if docs touched)
     - [ ] <reviewer-facing checks, e.g. "browse the rendered site for visual regressions">

     🤖 Generated with [Claude Code](https://claude.com/claude-code)
     EOF
     )"
     ```

   - **PR exists** → update title + body only:

     ```bash
     gh pr edit --title "..." --body "..."
     ```

     Never close/reopen, never re-request review, never touch labels or milestone unless the user explicitly asks.

   - **Backfill PR number in lessons.** If `design/lessons.md` was created or modified in this run, replace the placeholder: `sed -i "s/PR #TBD/PR #<N>/g" design/lessons.md`, then amend the relevant commit: `git commit --amend --no-verify --no-edit design/lessons.md`.

3. **Title style** - mirror the most significant commit. If the branch is multi-purpose, lead with the most user-visible scope. Keep under ~70 chars (the GitHub list view truncates).

4. **Body style** - this repo's PR template is two sections:
   - **`## Summary`** - short bullets, one per logical change. Lean on the consolidated commit messages; this is not the place to repeat them verbatim, but rather to surface the *why* a reviewer needs to know.
   - **`## Test plan`** - checklist. Use `[x]` for what you actually ran (`make lint`, `mkdocs build --strict`), `[ ]` for reviewer-facing manual checks (browse the rendered site, click links, etc.). If the change is hooks/tooling, the reviewer checks usually run the hook against a contrived input.

5. **Append the Claude Code attribution trailer** on the last line of the body (the convention used by other PRs in this repo). Do not put it inside a section.

### Phase 4.5: Address PR review comments (optional)

After Phase 4 pushes and creates/updates the PR, drive the GitHub Copilot **server-side PR review** to a clean state. This is **independent of the Copilot CLI** used in Phase 1.5 - it uses `pr_review.py` (not raw `gh` commands) to interact with GitHub's review API.

**Entry point:** always use `pr_review.py` subcommands - never run `gh pr edit --add-reviewer` or raw `gh api graphql` mutations as one-offs. `pr_review.py` centralizes the trigger/wait/resolve logic so this phase's state machine has a single tested code path; ad-hoc `gh` calls drift from the script's idempotency, login-alias, and JSON-output guarantees. The correct sequence is:

```bash
uv run --frozen python .claude/skills/address-pr-review/scripts/pr_review.py state    # detect review state (A/B/C/D)
uv run --frozen python .claude/skills/address-pr-review/scripts/pr_review.py trigger  # request Copilot review
uv run --frozen python .claude/skills/address-pr-review/scripts/pr_review.py wait --timeout 480  # poll until complete
uv run --frozen python .claude/skills/address-pr-review/scripts/pr_review.py resolve <thread-id>  # resolve a thread
```

1. **Skip-check.** If the user passed `--skip-review`, announce the skip and stop. (Same flag skips Phase 1.5.) This is the **only** skip condition - unlike Phase 1.5, Phase 4.5 does not depend on the `copilot` CLI binary being on PATH. **Never skip because a raw `gh` command failed** - use `pr_review.py` which handles the API correctly.
2. **Iteration loop (cap at 2):**
   - Use `pr_review.py state` to detect current state, then `trigger` + `wait` to get the review, then process unresolved fresh threads per the `/address-pr-review` skill (run only address-pr-review's Phase 1-3 - skip its Phase 4 commit; commits are handled by the prepare-pr Phase 2 re-cut below). Drive from any state (A/B/C/D) to either State D (clean - done) or "fixes applied, ready for re-cut."
   - **If no fixes were applied** (State D reached without code edits, or all unresolved threads were `resolve-only`/`skip`-leave-open) → done. Exit.
   - **If fixes were applied** → re-run Phase 2 (soft-reset + recommit, NO Phase 1.5) → re-run Phase 3 (lint-diff) → re-run Phase 4 (force-push + update PR body). The new push triggers a fresh Copilot review automatically.
3. **After 2 iterations:** if fixes are still being made, surface to user: "2 fix cycles complete. Run `/address-pr-review` manually if more comments arrive." Stop.

Non-blocking: if `/address-pr-review` reports a timeout (Copilot didn't respond within 5 min) or fails non-recoverably, log the warning and continue. The PR is pushed; the user can address comments manually.

The state-aware skill is the brain - Phase 4.5 just orchestrates the iteration cap and the Phase 2 re-cut. All freshness detection, polling, and resolution logic lives in `pr_review.py` where it can be tested independently.

## Anti-patterns

- **`git push --force`** without `--with-lease` - clobbers remote commits you haven't seen.
- **Force-pushing to the trunk branch or any well-known trunk name (`main`, `master`, `develop`, `trunk`, `prod`, `release/*`)** - Phase 1 step 2 guardrail must refuse. The literal list is a safety net for repos where trunk resolution somehow returned the wrong name.
- **Hard-coding `main` in any new `git`/`gh` invocation** - this skill is a gallery item, copied across repos that use `main`, `master`, `prod`, etc. Resolve trunk via `extract_signals.py trunk-name` / `trunk-ref` and substitute the printed value as a literal argument in the next command. Hard-coding `main` works here and silently breaks the next repo.
- **Using `eval`, `$(...)` substitution, or shell variables to plumb trunk values between commands.** The agent's `Bash` tool runs every command in a fresh shell, so any `eval`'d variable is gone by the next call. Worse: compound commands with `$(...)` or `eval` are flagged by the permission matcher as "shell syntax that cannot be statically analyzed" and trigger an approval prompt every time. Always run the script command first, **read the printed value from the output**, then issue the next command with that value as a literal argument. Plain `git`/`gh` commands without substitution match cleanly against the allow-list and run silently.
- **Resetting to the trunk *tip* (`git reset --soft <trunk-ref>`) in Phase 2 instead of the merge-base** (`git reset --soft <merge-base-sha>`, obtained from `extract_signals.py phase2-base`). Tip-reset is only safe when nothing landed on trunk between branch-cut and now. If trunk advanced, the post-reset commits diff against the new tip and look like they're reverting the unrelated trunk changes that happened in between. The `phase2-base` helper always returns the merge-base; use it every time.
- **Skipping Phase 1 step 1 (`sync-trunk`).** A stale local trunk poisons every merge-base, diff, and `make lint-diff --from-ref main` downstream - the branch looks like it contains commits that are already merged, and the Phase 2 soft-reset can target a base far behind the real merge-base. `sync-trunk` fast-forwards the local trunk from origin before anything reads it. It's not optional and it's not the same as `phase2-base` preferring `origin/<name>`: the `origin/` preference fixes the skill's *own* merge-base calls, but the repo's Makefile reads the *local* ref, so both the fetch/ff and the origin-preference are needed. On `diverged` (exit 1), stop - don't rewrite history on top of an out-of-sync trunk.
- **`git add .` or `git add -A`** in Phase 2 - the active scope is what *you* want in each commit, not whatever happens to be in working tree. Always explicit file lists.
- **Skipping `make lint-diff` after Phase 2.** Per-commit hooks were bypassed via `--no-verify`; `make lint-diff` is the validation gate. Skipping it means pushing unvalidated state.
- **Using `make lint` instead of `make lint-diff` after Phase 2.** Post-commit there are no uncommitted changes for `make lint` to operate on. `make lint-diff` runs hooks against the trunk-to-HEAD diff, which is the actual scope to validate.
- **Auto-running consolidation on a clean branch.** Adds noise (force-push for no benefit, lost commit timestamps) when the branch was already in PR shape. Phase 1 step 8 is the gate - trust it.
- **Squashing without explanation.** If you collapse 5 commits with distinct semantics into one `chore: misc updates`, the reviewer (and `git blame` six months later) can't tell what changed why. The whole point of the per-prefix consolidation is that each commit has a *clear scope*.
- **Stuffing tooling changes into a `docs(...)` commit.** Reviewers triage by scope; mixing scopes makes it harder to revert one change without the other.
- **Adding the Claude Code attribution trailer to commit messages, not just the PR body.** This repo's convention is the trailer goes in the PR body and (per the global Bash safety doc) in commits authored by Claude. Be consistent with the project's existing commits - check `git log` recent samples.
- **Re-requesting review on update.** Updating the PR body or pushing a new revision shouldn't ping the reviewer again. `gh pr edit` for body, plain `git push --force-with-lease` for code, nothing else.
- **Running `/second-opinion` after Phase 2 (soft-reset).** The soft-reset is the point of no return for commit topology; review-driven fixes after that need a second reset cycle. Phase 1.5 fires *before* Phase 2 by design - fixes land in WIP commits and Phase 2 absorbs them for free.
- **Invoking `/second-opinion` with no commits ahead of trunk.** `/second-opinion` reviews `git diff <base>..HEAD`. If the branch is at parity with the trunk and all work is uncommitted, the diff is empty, the reviewer reports "no findings," and the agent (and the user) thinks the code passed review when it was never actually reviewed. Phase 1.5 step 2's pre-flight WIP-commit + Phase 2's merge-base soft-reset is the workaround - never invoke `/second-opinion` on an empty `<base>..HEAD` diff and treat success as meaningful.
- **Skipping Phase 1.5 step 2 (preflight-wip) when the branch already has committed changes ahead of trunk.** The preflight applies in BOTH "no commits, dirty tree" AND "some commits + dirty tree" cases - the script's whole purpose is to make the right call so the agent can't reason its way past it. The failure I saw firsthand: branch had 2 committed changes + 8 uncommitted files; agent skipped preflight ("there's already a diff for Copilot to see"); `/second-opinion` reviewed only the 2 old commits and returned "No findings," missing every line of the 8 uncommitted files. The script is self-applying for exactly this reason - always run `extract_signals.py preflight-wip` unconditionally in Phase 1.5, every time, no judgment call.
- **Skipping Phase 4.5 because `copilot` CLI is missing.** Phase 4.5 uses the GitHub server-side Copilot reviewer via `gh` CLI - it does NOT use the `copilot` CLI binary. Only `--skip-review` should skip it. Phase 1.5 is the one that needs the `copilot` CLI.
- **Assuming `copilot` CLI is not installed without running `command -v copilot`.** In VS Code Server / WSL environments, copilot lives at `~/.vscode-server/.../copilotCli/copilot` and is on PATH. Always run the check.
- **Auto-applying `/second-opinion` findings without challenge.** The reviewer is a different model with limited project context. It will misread intentional regex patterns, flag documented conventions, and suggest "fixes" that break scoping or logic. Every finding must be validated against the author's intent before acting. When uncertain, surface to the user - never auto-fix on faith.
- **Skipping Phase 1.5 or 4.5 based on your own judgment** ("it's just a new file", "small change", "no existing code modified"). The ONLY skip condition is `--skip-review`. New features are the MOST important case for review - fresh code has no prior review coverage and no test history. The `/second-opinion` run on `bootstrap-docs` caught two real bugs in brand-new code. Never invent skip reasons that aren't in the skill.
- **Writing session-specific notes in `design/lessons.md` instead of generalized rules.** Each entry is a forward-looking rule, not a journal entry. "When adding a new vault, create `.nav.yml` before content files" is a rule. "I forgot `.nav.yml` for tls-certificates-kb" is a journal entry.
- **Extracting more than 3 learnings per PR.** A noisy ledger gets ignored. Pick the 3 with broadest applicability. If you genuinely have 5+ signals, the branch was too large - note that as one of the 3.
- **Skipping Phase 1.5c (ARCHITECTURE.md review).** New skills, hooks, and vault structure changes are the most common sources of staleness. The review takes seconds; the staleness costs hours when a future agent acts on outdated information.

## Example invocations

- `/prepare-pr` - full pipeline against the current branch
- `/prepare-pr --skip-review` - skip Phase 1.5 (`/second-opinion`) and Phase 4.5 (`/address-pr-review`); use when Copilot is offline or you've already run reviews manually
- "wrap this branch up as a PR" - same workflow
- "update the PR with the new commits" - re-run; Phase 1 detects existing PR, Phase 4 takes the update path
- "the branch is already clean, just lint + push + PR" - skill detects this in Phase 1 step 8 and skips Phase 2 automatically; the user's framing just confirms the heuristic
