# Retro: bar profiles rework (spec #1, PR #10)

Session of 2026-10-23. Covers: grilling → spec #1 → tickets #2–#9 → `/implement-spec` with parallel implementer subagents → two-axis code review → fixes → merge.

**Outcome:** merged, 130 tests, the live config migrated to schema 9. The review caught one data-loss bug (story 59) and about 13 other findings. All were fixed in one pass before the merge.

Candidates below are suggestions for the agent's **environment**, ordered by severity. Nothing here has been applied yet.

---

## 1. No guardrail runs the tests (Automated checks)

**What happened:** #2 created `common/.config/quickshell/tests/run.sh`, but nothing runs it: no pre-commit hook and no CI job. Every agent ran the tests by hand because the prompt told it to. A human editing QML would never trigger them. `qmllint` isn't wired in anywhere either.

**Suggestion:** add a GitHub Actions job that runs `tests/run.sh` on every push/PR touching `common/.config/quickshell/**`, plus a local pre-commit hook running the same script. Keep `qmllint` advisory only: it reports existing unqualified-access warnings on `main`.

**Gotcha to preserve:** `/usr/bin/qmltestrunner` is the Qt5 build and fails. `run.sh` already uses `/usr/lib/qt6/bin/qmltestrunner`, so CI must install Qt6 declarative and point at the same binary.

## 2. Migration tests passed with a migration that lost data (Automated checks / Coding standards)

**What happened:** the migration overwrote the old active profile's top-level values (story 59). All migration tests used a copy of the real `appearance.json`, and in that file the top-level values happen to equal the saved `minimal` profile. So the bug was invisible to the tests and only the spec-axis reviewer found it, by building a divergent fixture in node.

**Suggestion:** this is a judgement call, so it belongs in the reviewer's standards, not a lint rule. Add `CODING_STANDARDS.md` with one rule:

> Migration tests include at least one fixture where every value the migration moves differs from its destination's existing value, so a dropped or overwritten value fails the test.

Point to it from `docs/agents/` so `/code-review` picks it up.

## 3. The repo is the live desktop, and nothing says so (Navigation / Information access)

**What happened:** `~/.config/quickshell` is a stow symlink into the main checkout. Checking out a branch, pulling, or running a migration there rewrites the running desktop's config, and Quickshell hot-reloads it. The orchestrator worked this out by hand and wrote safety rules into a scratchpad note: never touch the main checkout, and run `qs -p <worktree>` only. That note dies with the session.

**Suggestion:** add a navigation pointer to `CLAUDE.md` (it loads every turn, so one line):

> This repo is stowed into `~` and is the live desktop config: work in a worktree and verify Quickshell with `qs -p <worktree>/common/.config/quickshell`. Runtime state files: see `docs/agents/live-config.md`.

Put the details in `docs/agents/live-config.md`: which files Quickshell rewrites at runtime, why `qs -p` keeps it away from the live JSON, how to kill only your own instance, and that a pull on `main` migrates live data.

## 4. Runtime state files are tracked in git (Information access)

**What happened:** `config/appearance.json`, `config/monitors.json`, `config/wallpapers.json` and `services/launcher.json` are written by Quickshell at runtime: recent apps, wallpaper picks, and before the fix, every unsaved slider move. They showed up as noise in the starting `git status`, every agent's `qs -p` run dirtied them and had to revert them by hand, and the migration left them modified after the merge.

**Suggestion:** decide per file whether it is config or state:
- Keep the curated defaults tracked, e.g. as `*.default.json`.
- Let Quickshell write the live copy to an untracked path (or `$XDG_STATE_HOME`), seeded from the default on first run.
- `launcher.json`'s recent list is pure state and can be untracked outright.

This needs a decision from you before anyone builds it.

## 5. Avoided glossary terms leaked into code (Coding standards → deterministic check)

**What happened:** implementers kept or introduced terms the glossary marks `_Avoid_`: `StatusModules`, `moduleItem`, "DOCKED ISLAND BAR", `currentLayout`, `structuralVerticalPadding`. The standards reviewer caught them, but only at the end, after nine branches had built on those names.

**Suggestion:** the violation is **mechanical** (a banned token in an identifier or UI label), so a check beats a rule. Write a small script that reads the `_Avoid_` lists from each `GLOSSARY.md` listed in `GLOSSARY-MAP.md` and greps changed `.qml`/`.js` lines for them. Allowlist migration code that has to name legacy keys (`SchemaMigrations.js`, `tests/fixtures/`). Wire it into the guardrail from #1.

## 6. A spec deviation spread before review saw it (Tool economy / process)

**What happened:** #7 persisted pending changes to JSON instead of keeping them in memory, against the spec. Its report mentioned the change but didn't present it as a departure from the spec. #8 and #9 then built on top of it, and the single `/code-review` at the end found it along with the story-59 bug it caused. The fix pass cost about 270k tokens and 22 minutes.

**Suggestion:** in the `implement-spec` flow, have each implementer finish by listing every place it departed from the ticket or spec ("none" is a valid answer). Have the orchestrator stop the frontier on any departure until it's resolved. That keeps the full review at the end, but catches spec departures one ticket at a time instead of nine.

## 7. Parallel tickets collided on the migration chain (Ticketing)

**What happened:** #3, #4, #5, #6 and #9 each added a migration step. The chain, `schemaVersion` and the runner didn't exist until #3, so #4's own load-time hook had to be replaced in a merge. The orchestrator had to message running agents to renumber their steps (step 3, step 4…).

**Suggestion:** when `/to-tickets` sees several tickets extending one shared mechanism (a migration chain, a registry, a routing table), the prefactor ticket should create that extension point empty: a chain with step 0 and the runner. Later tickets then each add one entry. Worth a line in the `to-tickets` skill's prefactoring guidance.

## 8. Host-specific values in `common/` (Automated checks)

**What happened:** commit `5d67bda` (from before this session's code, merged with PR #10) puts `eDP-1` disabled plus the AOC and Philips monitor layout in `common/.config/hypr/modules/monitors/monitors.lua`. That applies to every host, including the laptop.

**Suggestion:** move the block to the matching `host-*/` folder. Optionally add a guardrail check that flags `desc:` monitor identifiers and output names under `common/`.

## 9. Worktree placement and base (Environment)

**What happened:** the harness created agent worktrees under `.claude/worktrees/` inside the repo (now gitignored), and some started from `main` instead of the integration branch. #8 had to `reset --hard` onto it. The "confirm your base" step in the implementer prompt caught this every time, so nothing broke.

**Suggestion:** none needed beyond keeping that confirmation step in the implementer prompt. Recorded so it isn't rediscovered.

---

## Minor

- **Permission check on merge:** `gh pr merge` was blocked by the auto-mode classifier, and you ran the merge yourself. If you want agents to merge, add a permission rule for it.
- **Ambiguous verb:** "close the PR" was taken literally and the PR was closed instead of merged. Reopening fixed it, and nothing was lost.
