# Milestone 0 execution plan: upgrade branch established

**Written:** 2026-10-19, against `origin/main` at `ec89371224`.
**Milestone:** M0 of the Firefox 157.x upgrade, Jira epic MOB-5026 (do not touch Jira, see rules).
**Goal:** the 155.1 upgrade lives on a local `upgrade/firefox` branch that descends from today's `main`, builds, passes all unit tests and lint, records its Firefox base, has a diary, has CI triggers ready, and has a proven script that merges new `main` work into it.

This file is written so that an agent with no memory of the planning conversation can execute it step by step. Read all of section 1 before running anything.

---

## 1. Read this first (rules for the executing agent)

### 1.1 Hard rules

1. **Everything stays local.** Never run `git push`, `gh` (any subcommand), or any Jira/Atlassian tool. Never change GitHub settings.
2. **Never touch the main checkout's work.** The main checkout is `/Users/dariocarlomagno/Workspace/ecosia/ios-browser`. It has an unrelated uncommitted change in `.github/workflows/merge_tests.yml` (MOB-4907 work). Do not stage, stash, reset or edit anything there, except reading files and running `git worktree` / `git fetch`.
3. **All upgrade work happens in the worktree** `/Users/dariocarlomagno/Workspace/ecosia/ios-browser-upgrade` on the local branch `upgrade/firefox`.
4. **Commits are local and carry real dates.** Never set `GIT_AUTHOR_DATE` / `GIT_COMMITTER_DATE`, never touch file timestamps.
5. **No history rewriting** on `upgrade/firefox` once ticket 01 is done: no `rebase`, no `reset --hard` to an older commit, no `commit --amend` of merge commits, no `--force` anything. If something is wrong, add a new commit. (Exception: `git merge --abort` during a merge in progress is fine.)
6. **Only run the git operations this plan lists.** If a step seems to need something else, stop and ask (section 1.3).
7. **Every ticket ends with a diary entry** (format in appendix A) and an update of the progress file (section 1.2).
8. **Long commands run in the background** (builds, tests, `tuist-setup.sh`). Write their output to a log file and poll it. Do not sleep in the shell; use the await tool.

### 1.2 Progress file

Keep `/Users/dariocarlomagno/Workspace/ecosia/ios-browser-upgrade/.scratch/firefox-upgrade/m0-progress.md` current (template in appendix B). Update it:

- when you start a step (`In progress: <step>`),
- when you finish one (tick it, note the commit hash),
- whenever you stop for a human (write the exact question under `## Waiting on Dario`).

On resume, read this plan and the progress file, then continue from the first unticked step. Before step 0 exists, there is no progress file: start at section 2.

### 1.3 When to stop and ask Dario

Stop, write the question in the progress file, and end your turn with that question when:

- a prerequisite in section 2 is missing,
- a merge conflict's correct resolution is not obvious from the `// Ecosia:` / `/* Ecosia: */` comments and the commit history (rules in step 4),
- a build error or test failure cannot be traced to the upgrade or the merge within two focused attempts,
- the plan's facts (section 3) no longer match what you see, in a way that changes what to do (for example, more or different conflicting files),
- anything would require a remote action.

Do not stop for things this plan already decides.

### 1.4 Ticket map

| Step | Ticket | Jira | Summary |
| --- | --- | --- | --- |
| 0 | — | — | Prerequisites and worktree setup |
| 1 | 01 | MOB-5027 | Graft the 155.1 upgrade onto `main` |
| 2 | 03 | MOB-5029 | Record the upstream base |
| 3 | 06 | MOB-5032 | Start the upgrade diary, bring planning docs |
| 4 | 02 | MOB-5028 | Merge `main`, resolve conflicts, green build |
| 5 | 05 | MOB-5031 | CI triggers for `upgrade/firefox` (branch rules as a checklist) |
| 6 | 04 | MOB-5030 | Main sync script, tests, workflow, local proof |
| 7 | — | — | Close-out: review, M0 diary summary, retro |

Full ticket texts: `.scratch/firefox-upgrade/issues/NN-*.md` (available in the worktree after step 3; before that, read them from the main checkout's stash with `git show 'stash@{0}^3:.scratch/firefox-upgrade/issues/<file>'`, see section 3).

---

## 2. Prerequisites (human)

Check each; if one fails, stop and ask Dario.

1. **Xcode:** use the installed Xcode 27.0 (`/Applications/Xcode.app`, the selected one; check `xcodebuild -version`). Record the version in the progress file as `XCODE`.
   CI pins Xcode 26.6 (`.github/actions/prepare_environment/action.yml`), and its comments warn that Xcode 27 can fail this project with thousands of duplicate symbols. The cause: Xcode 27 statically folds SPM library products into consumer targets, and `-ObjC` (in `EcosiaDebug.xcconfig`, `EcosiaBetaDebug.xcconfig`, inherited by the `Testing` configuration) then force-loads both copies. Neither `main`, the 155.1 tree nor upstream `firefox-v157.1` gates `-ObjC` by Xcode version. Whether it bites locally is unknown, so step 4f checks it first (the **Xcode 27 gate**). Do not install another Xcode and do not run `xcode-select -s`.
2. **iPhone 17 simulator** available: `xcrun simctl list devices available | grep 'iPhone 17 ('` (present on 2026-10-19).
3. **Tools:** `tuist`, `swiftlint`, `actionlint`, `npm`, `python3` on PATH (all present on 2026-10-19).
4. **Staging config:** `/Users/dariocarlomagno/Workspace/ecosia/ios-browser/firefox-ios/Client/Ecosia/BuildSettingsConfigurations/Staging.xcconfig` exists (it does; it is untracked and gets copied into the worktree in step 0).

---

## 3. Facts as of 2026-10-19

Verify the first four with the commands given before step 1. If they differ, see 1.3.

- **Squash point on `main`:** `89e13a568d`. The 155.1 experiment was squashed from it.
- **155.1 squash commit:** `c162a7c953` on `origin/firefox-upgrade-155.1`. Its tree is the upgrade.
- **Commits on the 155.1 branch after the squash** (`git log --oneline c162a7c953..origin/firefox-upgrade-155.1`), all pre-decided in step 1:
  - `a9bd75f175` docs: 155.1 experiment tickets (`.scratch/firefox-upgrade-155-1/issues/`, 20 files incl. `00-unassigned-conflicts.md`), rebase manifest and scripts (`firefox-ios/Tuist/upgrade/rebase-manifest-155.1/`, `firefox-ios/Tuist/upgrade/CONTEXT.md`), a personal agent-skills overlay (`AGENTS.md`, `CONTEXT-MAP.md`, `docs/agents/*`), and a trailing newline in `firefox-ios/Client/Configuration/version.xcconfig`.
  - `f40d8cfe27`, `5caded1d8b`, `0df4b73f44`, `b594f0dd05`, `1fb00da694`, `28d0428c63`, `8470b74e03`: CI experiments touching only `.circleci/config.yml` (SPM cache commented out), `fastlane/Fastfile` (`-skipMacroValidation -skipPackagePluginValidation`, `verbose: true`) and `Gemfile.lock`.
- **Dry run of graft + merge of `origin/main` (`ec89371224`)** conflicts in exactly 3 files, all from `55fd31ac05 [MOB-4990] Fix invisible auth tab leaks and session transfer ordering (#1308)`:
  - `firefox-ios/Client/TabManagement/TabManager.swift`
  - `firefox-ios/Client/TabManagement/TabManagerImplementation.swift`
  - `firefox-ios/firefox-ios-tests/Tests/ClientTests/Mocks/MockTabManager.swift`
- **Firefox-core files `main` changed since the squash point that merge without conflict** (must still be checked in step 4): `firefox-ios/Client/Application/AppDelegate.swift`, `.../BrowserViewController/Extensions/BrowserViewController+WebViewDelegates.swift`, `.../BrowserViewController/Views/BrowserViewController.swift`, `firefox-ios/Client/Frontend/Browser/TopTabDisplayManager.swift`, `firefox-ios/Client/Frontend/Home/Homepage/HomepageViewController.swift`, `.../Wallpapers/v1/Interface/WallpaperManager.swift`, `firefox-ios/Client/TabManagement/Tab.swift`, `.../ClientTests/CreditCard/CreditCardValidatorTests.swift`, `.../ClientTests/Wallpaper/WallpaperManagerTests.swift`, `tuist-setup.sh`, `perform_snapshot_tests.sh`, `.taskcluster.yml`, plus `.github/**`.
- **Firefox tags present:** `firefox-v155.1`, `firefox-v157.0`, `firefox-v157.1`. M0 only uses `firefox-v155.1`.
- **Planning docs** are in the main checkout's stash as `stash@{0}` ("WIP: Firefox 157 upgrade planning ..."). It contains: modified `adr/README.md`; untracked `.scratch/firefox-upgrade/` (milestones, spec, 32 issue files), `GLOSSARY-MAP.md`, `adr/0007-graft-firefox-upgrades-onto-main-via-upgrade-branch.md`, `firefox-ios/EcosiaUpgrade/GLOSSARY.md`. Untracked files live in the stash's third parent (`stash@{0}^3`). If the stash index changed, find it with `git stash list | grep 'Firefox 157 upgrade planning'`.
- **Git hooks in a worktree:** `post-checkout` and `bootstrap.sh` try to copy hooks into `.git/hooks`, which fails in a worktree because `.git` is a file there. The error is harmless; ignore it. The personal `AGENTS.md` overlay hook does not run in the worktree. `prepare-commit-msg` adds no ticket prefix on `upgrade/firefox`, so write `[MOB-XXXX]` prefixes yourself.
- **Expected soon on `main`: squash merge of `dc-mob-4907-merge-tests-triggers`** (MOB-4907, 9 commits, CI only). It changes `merge_tests.yml` and `snapshot_tests.yml` (new `paths-ignore` entries right below the `branches:` line, nightly `schedule`, per-PR `concurrency` with cancel-in-progress, skip on version-only bumps), saves compilation caches on `main` only, adds `purge_caches.yml` and `.github/scripts/{purge_caches,only_marketing_version_changed}.sh`, changes `check_snapshot_updates.sh`, and adds `firefox-ios/Ecosia/Ecosia.docc/CI_WORKFLOWS.md`. It does not change the `branches:` lists or `perform_unit_tests/action.yml`, so `verify.sh` stays valid. It arrives like any other `main` commit (a squash on `main` makes no difference to merging `main` into `upgrade/firefox`). Where it lands in this plan:
  - **Before step 4's fetch:** nothing special; step 4 merges it, and step 5 edits the new files.
  - **After step 5:** it textually conflicts with step 5's one-line trigger edits, because its `paths-ignore` lines sit right next to them. Resolve by taking `main`'s version of each conflicted workflow file and re-adding `'upgrade/firefox'` to its `branches:` list. That's a pre-decided resolution: no need to ask. This is a good real commit for step 6d's proof, exercising the conflict path.
  - The `main` checkout's uncommitted `merge_tests.yml` change belongs to this MOB-4907 work. Still don't touch it (rule 1.1.2).
- **How CI runs unit tests** (`.github/actions/perform_unit_tests/action.yml`): scheme `Ecosia`, configuration `Testing`, destination `platform=iOS Simulator,name=iPhone 17`, `build-for-testing` then `test-without-building`. Lint: `swiftlint --strict` from the repo root.

Verification commands:

```bash
cd /Users/dariocarlomagno/Workspace/ecosia/ios-browser
git fetch origin main firefox-upgrade-155.1 --tags --quiet
git cat-file -t 89e13a568d && git cat-file -t c162a7c953          # both: commit
git log --oneline c162a7c953..origin/firefox-upgrade-155.1 | wc -l   # 8
git stash list | grep 'Firefox 157 upgrade planning'                 # one line
```

---

## 4. Steps

### Step 0: worktree setup

```bash
cd /Users/dariocarlomagno/Workspace/ecosia/ios-browser
git fetch origin main firefox-upgrade-155.1 --tags --quiet
git worktree add --detach ../ios-browser-upgrade 89e13a568d
```

The worktree starts detached on the squash point; step 1 creates the branch. Then:

```bash
cd ../ios-browser-upgrade
mkdir -p .scratch/firefox-upgrade
cp ../ios-browser/.scratch/firefox-upgrade/m0-plan.md .scratch/firefox-upgrade/m0-plan.md
```

Create `.scratch/firefox-upgrade/m0-progress.md` from appendix B. From now on, work only in the worktree and read the plan from the worktree copy.

**Done when:** `git worktree list` shows `ios-browser-upgrade`, and the progress file exists with step 0 ticked.

### Step 1 (ticket 01, MOB-5027): graft 155.1 onto `main`

**Decisions already made** (record them in the diary entry):

| Source | Decision | Reason |
| --- | --- | --- |
| `c162a7c953` tree | Graft as-is | It is the verified 155.1 upgrade (builds, 947 tests passed). |
| `a9bd75f175` experiment tickets and manifest | Not in the graft; preserved on `origin/firefox-upgrade-155.1`. Tickets are copied into the diary in step 3; the manifest and scripts move in M3 (ticket 14). | Keep the graft commit to "the upgrade" only. |
| `a9bd75f175` `AGENTS.md`, `CONTEXT-MAP.md`, `docs/agents/*` | Drop | Personal agent-skills overlay, superseded by `GLOSSARY-MAP.md`. |
| `a9bd75f175` `version.xcconfig` trailing newline | Drop | Cosmetic. |
| 7 CI experiment commits | Drop | Experiments for the experiment branch's CI. The final `-skipMacroValidation` Fastfile change only mattered because the SPM cache was disabled. Revisit only if archiving fails on this branch in M5. |

**Commands:**

```bash
cd /Users/dariocarlomagno/Workspace/ecosia/ios-browser-upgrade
TREE=$(git rev-parse 'c162a7c953^{tree}')
GRAFT=$(git commit-tree "$TREE" -p 89e13a568d -m "[MOB-5027] Graft Firefox 155.1 upgrade onto main

Tree of c162a7c953 (squashed Firefox 147 to 155.1 upgrade, origin/firefox-upgrade-155.1)
with main's 89e13a568d as parent, so main can merge into this branch (ADR 0007).")
git switch -c upgrade/firefox "$GRAFT"
```

The `.scratch/` copy made in step 0 is untracked and survives the switch.

**Verify:**

```bash
git log -1 --format='%P' HEAD                          # 89e13a568d... (full hash)
git diff --stat c162a7c953 HEAD | tail -1              # empty: identical tree
git rev-list --count HEAD                              # main's count at 89e13a568d + 1
git -C ../ios-browser status --short                   # main checkout unchanged (only merge_tests.yml)
```

**Diary:** the diary does not exist yet. Write the entry text into the progress file under `## Pending diary entries`; step 3 moves it into the diary.

**Done when:** all four checks pass.

### Step 2 (ticket 03, MOB-5029): record the upstream base

1. Create `firefox-ios/EcosiaUpgrade/UPSTREAM_BASE` with exactly one line, a tab between tag and hash, and a trailing newline:

   ```bash
   mkdir -p firefox-ios/EcosiaUpgrade
   printf 'firefox-v155.1\t%s\n' "$(git rev-parse 'firefox-v155.1^{commit}')" > firefox-ios/EcosiaUpgrade/UPSTREAM_BASE
   ```

   Expected hash: `04df3bd66b34441c6b97ee3958535c5bf4633ca4`. If different, stop and ask.
2. Create `firefox-ios/EcosiaUpgrade/README.md`, short, covering: what this folder is (Ecosia-owned Firefox upgrade tooling, records and diary; not part of any app target); `UPSTREAM_BASE` format (tag, tab, full commit hash) and meaning (the Firefox release this branch's Firefox code is built on, which `git merge-base` can no longer find after the graft); who updates it (whoever completes a move to a new upgrade target, in the same commit); how it is used (`git merge-tree --write-tree --merge-base=<tag> HEAD <new-tag>`).
3. Confirm the folder is in no Tuist target:

   ```bash
   rg -n 'EcosiaUpgrade' firefox-ios/Tuist firefox-ios/Project.swift || echo "not referenced"
   rg -n '"Ecosia[^/"]*/' firefox-ios/Tuist/ProjectDescriptionHelpers/*.swift
   ```

   The first must print `not referenced`. The second lists target source paths: on 2026-10-19 they all start with `Ecosia/` (for example `"Ecosia/**/*.{h,swift}"`), which cannot match `EcosiaUpgrade/`. If any entry is a pattern like `Ecosia*/**`, stop and ask.
4. Commit:

   ```bash
   git add firefox-ios/EcosiaUpgrade/UPSTREAM_BASE firefox-ios/EcosiaUpgrade/README.md
   git commit -m "[MOB-5029] Record the upstream base"
   ```

**Diary:** pending entry in the progress file, as in step 1.

**Done when:** `cut -f2 firefox-ios/EcosiaUpgrade/UPSTREAM_BASE` equals `git rev-parse 'firefox-v155.1^{commit}'`, and the commit exists.

### Step 3 (ticket 06, MOB-5032): start the diary, bring the planning docs

1. **Planning docs from the stash.** The stash's base commit is an older `main`, so restore paths rather than applying the stash:

   ```bash
   S=$(git -C ../ios-browser stash list | grep 'Firefox 157 upgrade planning' | cut -d: -f1)
   git checkout "$S^3" -- .scratch/firefox-upgrade GLOSSARY-MAP.md \
     adr/0007-graft-firefox-upgrades-onto-main-via-upgrade-branch.md \
     firefox-ios/EcosiaUpgrade/GLOSSARY.md
   git diff "$S^1" "$S" -- adr/README.md | git apply --3way
   ```

   - `git checkout <stash>^3 -- <paths>` stages those files; that is fine.
   - The worktree copy of `m0-plan.md` and `m0-progress.md` must survive: `.scratch/firefox-upgrade` in the stash does not contain them, so checkout only adds files. Verify both still exist afterwards.
   - If `git apply --3way` reports a conflict in `adr/README.md`, resolve it by keeping both sides' entries in number order.
   - Do **not** drop or pop the stash. Dario's main checkout still relies on it.
2. **155.1 experiment tickets**, copied unchanged:

   ```bash
   mkdir -p firefox-ios/EcosiaUpgrade/diary/155.1-experiment
   git archive a9bd75f175 .scratch/firefox-upgrade-155-1/issues \
     | tar -x -C /tmp && cp /tmp/.scratch/firefox-upgrade-155-1/issues/*.md firefox-ios/EcosiaUpgrade/diary/155.1-experiment/
   ls firefox-ios/EcosiaUpgrade/diary/155.1-experiment | wc -l      # 20
   ```

3. **`firefox-ios/EcosiaUpgrade/diary/README.md`:** the entry format from appendix A, plus these rules: one diary file per upgrade (`<target>.md`, this one is `157.md`); every ticket ends with an entry; engineers and agents write the same way, author marked; entries are appended, never rewritten (corrections are new entries); a milestone is done only when its entry exists.
4. **`firefox-ios/EcosiaUpgrade/diary/157.md`:**
   - Title, one-paragraph purpose, link to `.scratch/firefox-upgrade/milestones.md` and ADR 0007.
   - `## 155.1 checkpoint` section, written from the 20 experiment tickets: what the experiment did (inventory first, area-by-area resolution, 947 tests passing), the product decisions now in force (milestones.md "Product decisions" table), and **the full trap list**. The traps are in `155.1-experiment/19-integrate-and-verify.md` and scattered "trap" / "gotcha" / "lesson" notes in the other tickets: `rg -n -i 'trap|gotcha|lesson|pitfall|watch out' firefox-ios/EcosiaUpgrade/diary/155.1-experiment/`. Every trap gets one bullet with its source ticket number. Do not invent traps.
   - `## Entries` section, then the pending entries from steps 1 and 2 (moved out of the progress file), then this step's entry.
5. **Commit:**

   ```bash
   git add .scratch/firefox-upgrade GLOSSARY-MAP.md adr firefox-ios/EcosiaUpgrade
   git status --short          # nothing unexpected; m0-plan.md and m0-progress.md are included
   git commit -m "[MOB-5032] Start the upgrade diary and bring the planning docs"
   ```

**Done when:** the diary has the format, every trap from the experiment tickets, the 20 copied tickets, and three entries; the planning docs exist on the branch; the stash still exists in the main checkout.

### Step 4 (ticket 02, MOB-5028): merge `main`, resolve conflicts, green build

#### 4a. Build environment (once)

```bash
cd /Users/dariocarlomagno/Workspace/ecosia/ios-browser-upgrade
cp ../ios-browser/firefox-ios/Client/Ecosia/BuildSettingsConfigurations/Staging.xcconfig \
   firefox-ios/Client/Ecosia/BuildSettingsConfigurations/Staging.xcconfig
git status --short firefox-ios/Client/Ecosia/BuildSettingsConfigurations/   # must print nothing (ignored)
```

If `Staging.xcconfig` shows as untracked, stop and ask (it must never be committed).

#### 4b. Merge

```bash
git fetch origin main --quiet
MAIN_SHA=$(git rev-parse origin/main)
git merge --no-ff origin/main -m "[MOB-5028] Merge main into upgrade/firefox"
git diff --name-only --diff-filter=U
```

Record `MAIN_SHA` in the progress file. Compare the conflicted list with section 3. Extra files are fine to continue with, but list them in the diary; a long new list (more than 8 files) means stop and ask.

#### 4c. Resolve conflicts

For each conflicted file:

1. Understand both sides:
   - `main`'s intent: `git show 55fd31ac05 -- <file>` (and any other commit from `git log 89e13a568d..origin/main -- <file>`).
   - The upgrade's intent: `git diff 89e13a568d c162a7c953 -- <file>`.
2. Resolution rule: **keep the upgraded (155.1) structure and APIs, and re-apply `main`'s behavioural change on top of it.** `main`'s change is the Ecosia fix for invisible auth tab leaks and session transfer ordering. Every Ecosia line keeps or gets its `// Ecosia:` comment (multi-line: `/* Ecosia: ... */`), following `firefox-ios/Ecosia/Ecosia.docc/agents/ARCHITECTURE.md`.
3. Classify each resolution as **removal** (Ecosia removed Firefox code), **substitution** (Ecosia replaced it) or **addition** (Ecosia added code), for the diary.
4. Stop and ask if `main`'s change relies on an API that 155.1 removed or reshaped and the equivalent is not obvious.

After resolving: `rg -n '^(<<<<<<<|=======|>>>>>>>)' $(git diff --name-only HEAD)` prints nothing, then `git add` the files. **Do not commit the merge yet.**

#### 4d. Check what merged cleanly

1. Invisible auth tab work: find the files with `rg -l 'InvisibleTab|TabAutoCloseManager' firefox-ios/Client firefox-ios/Ecosia`. For each one that `main` changed since `89e13a568d`, read the merged version and confirm it compiles against the resolved `TabManager` API (the build will tell; read it now to catch logic issues).
2. Every Firefox-core file in section 3's "merge without conflict" list: run `git diff 89e13a568d "$MAIN_SHA" -- <file>`, then confirm each of those hunks is present in the working tree and still makes sense next to the 155.1 code around it. Note any hunk that no longer applies semantically (for example, it calls code 155.1 moved). Fix it, or stop and ask if the fix isn't obvious.

Then commit the merge:

```bash
git commit --no-edit
```

#### 4e. Verification script

Create `firefox-ios/EcosiaUpgrade/tools/verify.sh` (executable). It runs the same checks as CI's unit-test job and is reused by step 6:

```bash
#!/bin/bash
# Builds, unit-tests and lints the current checkout the way CI's merge tests do.
# Exit codes: 0 ok, 1 build failed, 2 tests failed, 3 lint failed.
set -uo pipefail

root=$(git rev-parse --show-toplevel)
cd "$root" || exit 1
logs="${VERIFY_LOG_DIR:-$root/build/verify}"
mkdir -p "$logs"
rm -rf "$logs/TestResults.xcresult"

common=(
  -scheme Ecosia
  -project firefox-ios/Client.xcodeproj
  -configuration Testing
  -enableCodeCoverage NO
  -destination 'platform=iOS Simulator,name=iPhone 17'
  -clonedSourcePackagesDirPath firefox-ios/SourcePackages
  -derivedDataPath DerivedData
)

echo "verify: building (log: $logs/build.log)"
xcodebuild "${common[@]}" build-for-testing > "$logs/build.log" 2>&1 || { echo "verify: build failed"; exit 1; }

echo "verify: testing (log: $logs/test.log)"
xcodebuild "${common[@]}" -resultBundlePath "$logs/TestResults.xcresult" test-without-building \
  > "$logs/test.log" 2>&1 || { echo "verify: tests failed"; exit 2; }

echo "verify: linting (log: $logs/lint.log)"
swiftlint --strict --quiet > "$logs/lint.log" 2>&1 || { echo "verify: lint failed"; exit 3; }

echo "verify: OK"
```

`build/` and `DerivedData` are already in `.gitignore` (checked 2026-10-19); confirm with `git check-ignore build/verify DerivedData`, which prints both.

#### 4f. Build and test

Run in the background, logging:

```bash
mkdir -p build
./tuist-setup.sh --no-open > build/tuist-setup.log 2>&1        # first run takes a while; runs bootstrap (npm, nimbus)
firefox-ios/EcosiaUpgrade/tools/verify.sh > build/verify-run.log 2>&1
```

Expect the harmless worktree hook error from bootstrap (section 3).

**Xcode 27 gate (check on the first build):** if `verify.sh` exits 1, run `rg -c 'duplicate symbol' build/verify/build.log`.

- **0 or no match:** the gate passed. Record `passed` in the progress file and go on with the fix loop below.
- **Any match:** this is the Xcode 27 linker problem from section 2, not something the merge caused. Don't try to fix it. Record `failed` in the progress file and stop and ask Dario. Put these options in the question:
  1. **Install Xcode 26.6** with Xcodes.app (matches CI), then re-run 4f with `DEVELOPER_DIR=<Xcode 26.6 path>/Contents/Developer` exported for every `xcodebuild`, `tuist` and `swiftlint` command.
  2. **Gate `-ObjC` by Xcode version** in the Ecosia xcconfigs (the approach upstream took in https://github.com/mozilla-mobile/firefox-ios/pull/34592), as its own commit. It changes linking for Xcode 27 only, so it also belongs on `main`, and the app must be smoke-tested afterwards, because missing Objective-C categories crash only at runtime.

  Include the first five `duplicate symbol` lines from the log in the question.

Local results come from Xcode 27, while CI uses 26.6. A warning or test that behaves differently between the two is noted in the diary. Once the branch is published, CI's result is the reference.

Fix loop:

- **Build errors:** fix them in the source. Usual causes are the merged `main` hunks from 4c and 4d calling pre-155.1 APIs. Each fix is a separate commit: `[MOB-5028] <what was fixed>`.
- **Test failures:** first run the failing class alone (add `-only-testing:<Target>/<Class>` to a copy of the test command) to rule out flakiness. Fix the code, or the test where the test asserts pre-155.1 behaviour. Before resolving a test in favour of the Ecosia side, check trap 6 from the experiment: make sure the Ecosia side is a real customization and not just older Firefox code.
- **Lint failures:** fix them; never add to `swiftlint_baseline.json` without asking.
- Must pass specifically: `FirefoxUpgradeCharacterizationTests`, and the invisible tab tests (`rg -l 'class InvisibleTab.*Tests' firefox-ios` finds them).
- Two failed attempts on the same failure: stop and ask (1.3).

When `verify.sh` prints `verify: OK`:

```bash
git add firefox-ios/EcosiaUpgrade/tools/verify.sh
git commit -m "[MOB-5028] Add a local verify script matching CI's merge tests"
```

(Commit `verify.sh` earlier if a fix commit needs it; order doesn't matter.)

**Diary:** one entry covering: `MAIN_SHA`; each conflict with its resolution type and reason; each clean-merged hunk that needed attention; each build or test fix; final test count and duration; any new trap.

**Done when:** no conflict markers remain, `verify.sh` passes, and the diary entry is written.

### Step 5 (ticket 05, MOB-5031): CI triggers and branch-rules checklist

1. Add `'upgrade/firefox'` to `on.pull_request.branches` in:
   - `.github/workflows/merge_tests.yml` → `[main, 'patch/**', 'develop', 'upgrade/firefox']`
   - `.github/workflows/swift_lint.yml` → `[main, 'patch/**', 'develop', 'upgrade/firefox']` (leave its `push:` section alone)
   - `.github/workflows/snapshot_tests.yml` → `[main, 'upgrade/firefox']`
   - `.github/workflows/snapshot_update_check.yml` → `[main, 'patch/**', 'upgrade/firefox']`

   Edit only those `branches:` lines. If MOB-4907's squash has already been merged (see section 3), the files also have `paths-ignore`, `schedule` and `concurrency` blocks; leave those as they are.
   Consequences of MOB-4907 to note in the diary entry, with no changes needed: PRs into `upgrade/firefox` restore `main`'s compilation cache but never save their own, so their CI is slower (mostly cache misses, since the code differs); nightly `schedule` runs cover the default branch only; per-PR concurrency cancels outdated runs on the long-lived sync PR, which is what we want.
   If `firefox-ios/Ecosia/Ecosia.docc/CI_WORKFLOWS.md` exists, add one short paragraph saying `upgrade/firefox` gets the same PR checks as `main` until the `main` migration (M5), and that the sync workflow exists (step 6).
2. `actionlint .github/workflows/*.yml` passes, or shows only findings that already exist on `origin/main` (compare by running it in the main checkout without editing anything).
3. CircleCI: `rg -n -B2 -A6 'branches:|filters:' .circleci/config.yml`. If any job PRs into `main` need is filtered to specific branches in a way that excludes `upgrade/firefox`, note it in the checklist below. Don't change CircleCI config without asking.
4. Create `firefox-ios/EcosiaUpgrade/publish-checklist.md`: the remote actions to do when Dario decides to publish M0, as checkboxes:
   - push `upgrade/firefox` to `origin`;
   - branch protection for `upgrade/firefox` matching `main`: no direct pushes, PRs need an approving review, the same required status checks as `main` (list the check names, taken from `main`'s protection in GitHub settings at publish time), merge commits allowed, linear history **not** required;
   - CircleCI findings from item 3, if any;
   - the items step 6 adds;
   - update Jira (M0 tickets' action items and statuses).
5. Commit: `[MOB-5031] Run PR checks on upgrade/firefox`.

**Done when:** the four triggers are edited, actionlint passes as defined in item 2, the checklist exists, and the diary entry is written.

### Step 6 (ticket 04, MOB-5030): main sync script, tests, workflow, local proof

#### 6a. Design (decided)

- **Script** `firefox-ios/EcosiaUpgrade/tools/sync-main.sh`. It lives on `upgrade/firefox`; the workflow checks out that branch before calling it.
- **Workflow** `.github/workflows/upgrade_main_sync.yml`. To run on pushes to `main` it must live on `main`, so it is written here and published to `main` later (publish checklist). It is the only upgrade piece that lands on `main`, and it touches no app code.
- **Sync mechanism:** a pull request with head `main` and base `upgrade/firefox`. GitHub keeps it current as `main` moves, so no bot branches are needed. When it's clean, enable auto-merge with **merge commit** (never squash or rebase: that would break the shared history). On conflict, mark it draft, comment the conflicting files, and request the owner's review.
- **Known trap:** pull requests created with the default `GITHUB_TOKEN` do not trigger other workflows, so CI would not run on the sync PR. The workflow uses a token secret, `UPGRADE_SYNC_TOKEN` (a PAT or GitHub App token with `contents:write` and `pull_requests:write`). Creating it goes on the publish checklist.

#### 6b. Script behaviour (write the tests first)

```
sync-main.sh [--base-ref <ref>]      # default origin/main
```

Run from a checkout of the upgrade branch. In order:

1. Not inside a git work tree → exit 64 with a message.
2. Working tree not clean (`git status --porcelain` non-empty; ignored files don't count) → exit 1, message `working tree not clean`.
3. `--base-ref` not resolvable → exit 64.
4. Base already contained (`git merge-base --is-ancestor <base> HEAD`) → print `already up to date`, exit 0, no commit.
5. `git merge --no-ff --no-edit <base>` succeeds → print the new HEAD hash, exit 0.
6. Merge conflicts → print each conflicted path on its own line (stdout, nothing else on stdout), `git merge --abort`, exit 2. The working tree is clean and HEAD unchanged afterwards.

The message on success uses git's default merge message. The script does not build or test (the PR's CI does that; locally, run `verify.sh` after it).

**Tests:** `firefox-ios/EcosiaUpgrade/tools/sync-main.test.sh`, plain bash, in the style of the repo's `.git/hooks/pre-push.test.sh` if present (otherwise: a `fail()` helper, one function per case, a temp dir per case via `mktemp -d`, and a summary line). Each case builds a tiny repo with a `main` and an `upgrade` branch that share history:

| Case | Setup | Expect |
| --- | --- | --- |
| clean merge | `main` adds file A, upgrade adds file B | exit 0, HEAD is a merge with 2 parents, both files present |
| up to date | no new `main` commits | exit 0, stdout `already up to date`, HEAD unchanged |
| conflict | both change line 1 of file C differently | exit 2, stdout exactly `C`, HEAD unchanged, `git status --porcelain` empty |
| dirty tree | uncommitted change on upgrade | exit 1, no merge attempted |
| bad ref | `--base-ref nope` | exit 64 |

Order: write `sync-main.test.sh`, run it and watch every case fail (the script doesn't exist yet), write `sync-main.sh`, run until all pass. Both files executable, `#!/bin/bash`, `set -euo pipefail` where it doesn't fight exit-code capture.

#### 6c. Workflow file

Create `.github/workflows/upgrade_main_sync.yml` along these lines (adapt names if actionlint asks):

```yaml
name: Sync main into upgrade/firefox

on:
  push:
    branches: [main]
  workflow_dispatch:

concurrency:
  group: upgrade-main-sync
  cancel-in-progress: false

permissions:
  contents: read

jobs:
  sync:
    runs-on: ubuntu-latest
    env:
      TARGET: upgrade/firefox
      OWNER: dariocarlomagno        # confirm the GitHub handle at publish time
      GH_TOKEN: ${{ secrets.UPGRADE_SYNC_TOKEN }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Stop when the upgrade branch no longer exists
        id: target
        run: |
          if git ls-remote --exit-code --heads origin "$TARGET" > /dev/null; then
            echo "exists=true" >> "$GITHUB_OUTPUT"
          else
            echo "$TARGET does not exist; nothing to sync."
          fi

      - name: Check for conflicts
        if: steps.target.outputs.exists == 'true'
        id: check
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
          git switch --detach "origin/$TARGET"
          set +e
          firefox-ios/EcosiaUpgrade/tools/sync-main.sh --base-ref origin/main > conflicts.txt
          code=$?
          set -e
          echo "code=$code" >> "$GITHUB_OUTPUT"
          if [ "$code" -ne 0 ] && [ "$code" -ne 2 ]; then exit "$code"; fi

      - name: Open or update the sync pull request
        if: steps.target.outputs.exists == 'true'
        run: |
          pr=$(gh pr list --base "$TARGET" --head main --state open --json number --jq '.[0].number')
          if [ -z "$pr" ]; then
            if git merge-base --is-ancestor origin/main "origin/$TARGET"; then
              echo "Already up to date."; exit 0
            fi
            gh pr create --base "$TARGET" --head main \
              --title "Sync main into $TARGET" \
              --body "Automatic merge of main into $TARGET. Merge with a merge commit, never squash or rebase."
            pr=$(gh pr list --base "$TARGET" --head main --state open --json number --jq '.[0].number')
          fi
          if [ "${{ steps.check.outputs.code }}" = "2" ]; then
            gh pr ready "$pr" --undo || true
            { echo "Conflicts with $TARGET:"; echo; sed 's/^/- `/; s/$/`/' conflicts.txt; } > comment.md
            gh pr comment "$pr" --body-file comment.md
            gh pr edit "$pr" --add-reviewer "$OWNER"
          else
            gh pr ready "$pr" || true
            gh pr merge "$pr" --auto --merge
          fi
```

`actionlint .github/workflows/upgrade_main_sync.yml` must pass. Add to the publish checklist:

- merge `upgrade_main_sync.yml` into `main` through a normal PR;
- create the `UPGRADE_SYNC_TOKEN` secret;
- enable "Allow auto-merge" in the repository settings if it's off;
- confirm the `OWNER` handle.

#### 6d. Local proof on a real `main` commit

```bash
git fetch origin main --quiet
git log --oneline HEAD..origin/main          # new main commits since step 4
```

- **There are new commits:** run `firefox-ios/EcosiaUpgrade/tools/sync-main.sh`, then `verify.sh` (background).
- **There are none:** stop and tell Dario that step 6d is waiting for `main` to move. Note it in the progress file. Everything else in step 6 can be committed before then.
- **Exit 2 (conflicts):** resolve with the step 4c rules via a manual `git merge --no-ff origin/main`, verify, and write a diary entry. If the conflicts are only the workflow trigger files from MOB-4907's squash, use the pre-decided resolution in section 3.

Commits:

- `[MOB-5030] Add the main sync script with tests`
- `[MOB-5030] Add the main sync workflow (to be published to main)`
- the proof merge itself (git's default merge message, from the script)

**Done when:** `sync-main.test.sh` passes; actionlint passes; a real `main` commit merged through the script and `verify.sh` passed afterwards; the publish checklist has the step 6 items; the diary entry is written.

### Step 7: close-out

1. **Code review:** run the `/code-review` skill against the fixed point `origin/main` (the spec is `.scratch/firefox-upgrade/spec.md` plus tickets 01–06). Most of the diff is the 155.1 upgrade itself, so tell the reviewers to focus on the commits after the graft: `git log --oneline <graft-hash>..HEAD`. Fix findings or record them for Dario.
2. **M0 diary summary** in `157.md`: what M0 delivered, the done-when check (builds, tests pass, sync proven locally), what remains remote (link the publish checklist), the traps added during M0, and time spent. Commit `[MOB-5032] M0 diary summary`.
3. **Retro:** run the `/retro` skill in the same session, before clearing context.
4. Update the progress file to `M0 local: done`, and tell Dario M0 is done locally and the publish checklist is ready.

Not part of M0: Jira updates, pushing, the publish checklist itself, and anything from M1 onward.

---

## Appendix A: diary entry format

```markdown
### YYYY-MM-DD: <ticket number and title> (<author: engineer name | agent: model name>)

**Milestone:** M0
**Commits:** <short hashes>

**Done:** what changed, in two to five sentences.

**Decided:** each decision with its reason. For conflicts: file, type (removal / substitution / addition), resolution, reason.

**Traps:** new pitfalls worth checking next time, or "none".
```

## Appendix B: progress file template

```markdown
# M0 progress

Plan: .scratch/firefox-upgrade/m0-plan.md
XCODE: <version, from prerequisites>
Xcode 27 gate (step 4f): <passed | failed, waiting on Dario>
MAIN_SHA merged in step 4: <hash>

## Steps

- [ ] 0 Worktree setup
- [ ] 1 Graft (MOB-5027): <commit>
- [ ] 2 Upstream base (MOB-5029): <commit>
- [ ] 3 Diary and planning docs (MOB-5032): <commit>
- [ ] 4 Merge main and green build (MOB-5028): <commits>
- [ ] 5 CI triggers and checklist (MOB-5031): <commit>
- [ ] 6 Main sync (MOB-5030): <commits>; proof: <done | waiting for main to move>
- [ ] 7 Close-out

In progress: <step and sub-step, or "nothing">

## Waiting on Dario

<questions, or "nothing">

## Pending diary entries

<entries written before the diary existed; empty after step 3>

## Log

- YYYY-MM-DD HH:MM <what happened>
