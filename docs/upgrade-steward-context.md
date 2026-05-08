# Upgrade Steward — context and handoff

This note captures why we built the Upgrade Steward, what exists in the repo today, and how to continue the work in a new chat or with another teammate.

## Why this exists

Firefox ships often. The Ecosia iOS app tracks Firefox but keeps many deliberate differences (homepage, native components UI, defaults, telemetry, auth flows, etc.). Upgrades are painful not only because of merge conflicts, but because it is hard to know **what upstream churn actually matters for Ecosia** and **where humans should spend review time**.

The Upgrade Steward is an early **review and guidance layer**: it compares two Firefox release refs, rescans the **current tree** for Firefox-side Ecosia customization markers (`// Ecosia:` and `/* Ecosia: … */`), intersects that with the upstream file delta, groups risk into product-facing areas, and emits reports humans can read without starting from a raw diff.

Long-term direction (not fully built yet): a background workflow that also runs Tuist/build/tests/screenshots and supports clearer merge policy — so upgrades cost less attention and Ecosia work stays focused on product-specific features.

## What is implemented today

| Piece | Path | Role |
| --- | --- | --- |
| Steward script | `firefox-ios/Tuist/upgrade/upgrade_steward.py` | Compare refs, rescan catalog, score impact, write JSON + HTML report + HTML presentation deck |
| Local runner | `firefox-ios/Tuist/upgrade/run-upgrade-steward.sh` | Ensures `firefox-origin` remote exists, delegates to the Python script |
| CI workflow | `.github/workflows/upgrade_steward.yml` | Manual **workflow_dispatch**: fetch two Mozilla `release/v*` branches, run steward, upload artifacts, write job summary |
| Ignored outputs | `.gitignore` entry `firefox-ios/Tuist/upgrade/demo-output*/` | Keeps generated report folders out of normal git noise |

Existing upgrade tooling (unchanged role): Tuist + `ecosia_conflict_helper.py` / catalog scripts — still the **merge-time** toolbox; the steward is **preflight and narrative** around an upgrade path.

## Branch and commits (when this was written)

Work landed on branch **`agentic-coding-hackathon`**, including roughly:

1. `aeb00c6813` — Add Upgrade Steward prototype (`upgrade_steward.py`)
2. `3e6ac971b1` — Wire CI workflow + `run-upgrade-steward.sh` + `.gitignore`
3. `7e3d202e5c` — Fix `GITHUB_OUTPUT` for recommendation strings with spaces

Rebase or cherry-pick onto **`main`** / **`develop`** as appropriate before merging.

## How to run locally

Ensure Mozilla branches are fetched (example):

```bash
git fetch firefox-origin release/v147.2 release/v150.0
```

Then either:

```bash
./firefox-ios/Tuist/upgrade/run-upgrade-steward.sh \
  --base-ref firefox-origin/release/v147.2 \
  --target-ref firefox-origin/release/v150.0 \
  --output-dir firefox-ios/Tuist/upgrade/demo-output-local
```

Or call Python directly from repo root:

```bash
python3 firefox-ios/Tuist/upgrade/upgrade_steward.py \
  --base-ref firefox-origin/release/v147.2 \
  --target-ref firefox-origin/release/v150.0 \
  --output-dir firefox-ios/Tuist/upgrade/demo-output-local
```

Omit `--base-ref` / `--target-ref` only if local `firefox-v*` branches and `firefox-origin/release/*` refs are set up as the script expects (see script defaults and inference logic).

Outputs:

- `upgrade-steward-report.json`
- `upgrade-steward-report.html`
- `upgrade-steward-presentation.html`

## How to run in CI

GitHub → **Actions** → **Upgrade Steward Report** → **Run workflow**.

Inputs default to `release/v147.2` → `release/v150.0` and remote name `firefox-origin`. Download the uploaded artifact for the HTML/JSON.

## Known limits (honest scope)

- Steward does **not** run `tuist generate`, `xcodebuild`, UI tests, or capture screenshots yet — those are the next wiring steps toward real autonomy.
- Customization detection is marker-based; divergence **without** `// Ecosia:` / `/* Ecosia:` will not appear in the catalog intersection.
- Recommendation scoring is heuristic; tune thresholds and area prefixes as you learn from real upgrades.

## Suggested next steps

1. Run the workflow on real release pairs the team cares about; tune risk buckets from feedback.
2. Add a **macOS** job (or follow-up workflow) for `tuist generate` and a minimal build/test slice after the report job.
3. Optional: post report summary or artifact link on upgrade PRs via `GITHUB_TOKEN`.
4. Decide merge policy: when steward says “blocked”, what human approvals are required.

---

## Prompt to continue this work elsewhere

Copy everything below the line into a new Cursor chat (adjust branch/repo if yours changed):

```
Continue the Ecosia iOS “Upgrade Steward” work.

Context doc (read first): docs/upgrade-steward-context.md

Goal: Reduce attention cost of Firefox uplifts by stewarding impact — compare Mozilla release refs vs current Ecosia customization markers, surface risky areas (homepage, native components UI, lifecycle, telemetry, etc.), emit JSON + HTML report + presentation; long-term add Tuist/build/screenshots and PR integration.

Repo: ecosia/ios-browser. Implementation lives under firefox-ios/Tuist/upgrade/ (upgrade_steward.py, run-upgrade-steward.sh), CI: .github/workflows/upgrade_steward.yml.

Recent commits on branch agentic-coding-hackathon: steward prototype, CI wiring, GITHUB_OUTPUT fix for spaced status strings.

Please: (1) confirm doc matches tree, (2) propose the next concrete wiring step I ask for [describe: e.g. macOS Tuist gate, PR comment bot, release watcher], (3) implement with minimal scope.

Constraints: marker catalog excludes some Ecosia-only dirs by design; steward uses repo root git diff — refs must exist after fetch.
```
