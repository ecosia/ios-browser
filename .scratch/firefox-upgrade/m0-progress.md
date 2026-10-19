# M0 progress

Plan: .scratch/firefox-upgrade/m0-plan.md
XCODE: Xcode 27.0 (27A266a), /Applications/Xcode.app
Xcode 27 gate (step 4f): <passed | failed, waiting on Dario>
MAIN_SHA merged in step 4: <hash>

## Steps

- [x] 0 Worktree setup
- [x] 1 Graft (MOB-5027): 0985241d04
- [x] 2 Upstream base (MOB-5029): 2f38473cab
- [ ] 3 Diary and planning docs (MOB-5032): <commit>
- [ ] 4 Merge main and green build (MOB-5028): <commits>
- [ ] 5 CI triggers and checklist (MOB-5031): <commit>
- [ ] 6 Main sync (MOB-5030): <commits>; proof: <done | waiting for main to move>
- [ ] 7 Close-out

In progress: 3 Diary and planning docs

## Waiting on Dario

Non-blocking (work continues; answer whenever):

1. **ADR number collision (step 3).** Upstream Firefox 155.1 ships `adr/0007-deeplink-startup-flow-refactor.md` (and 0008 to 0013), so Ecosia's `adr/0007-graft-firefox-upgrades-onto-main-via-upgrade-branch.md` shares number 0007 with an upstream ADR. Per the plan, `adr/README.md` now lists both 0007 entries in number order. Options: (a) leave as-is; (b) renumber Ecosia's to the next free number (0014), which upstream will likely collide with again on a later release; (c) give Ecosia ADRs their own namespace (for example `adr/ecosia-0001-...` or a folder under `firefox-ios/Ecosia/`), so upstream additions never collide. (b) and (c) need a new commit that updates links in milestones.md, spec.md, tickets 01, 06 and 23, GLOSSARY-MAP.md, the diary and the M0 plan; they can be done at any point without history rewriting.

## Pending diary entries

none (moved into firefox-ios/EcosiaUpgrade/diary/157.md in step 3)

## Log

- 2026-10-19 15:06 Prerequisites all pass (Xcode 27.0 27A266a, iPhone 17 sim 5ADBD44C, tuist 4.130.0, swiftlint 0.63.2, actionlint 1.7.12, npm 10.2.4, python3 3.12.2, Staging.xcconfig present). rg is only an interactive shell function, not on PATH for scripts; only used by the agent's own commands.
- 2026-10-19 15:06 Section 3 checks pass (89e13a568d and c162a7c953 are commits; 8 commits after squash; planning stash is stash@{0}; firefox-v155.1 = 04df3bd66b).
- 2026-10-19 15:06 Deviations from plan facts, judged not to change any step: (a) origin/main moved ec89371224 -> 7137bd6c30 ([MOB-4861], Ecosia auth files only); (b) the main checkout no longer has the uncommitted merge_tests.yml change: Dario committed it as 8dfff11020 on dc-mob-4907-merge-tests-triggers at 14:19 and fast-forwarded main. Main checkout baseline for "unchanged" checks is now `?? .scratch/` only.
- 2026-10-19 15:06 Step 0 done: worktree ../ios-browser-upgrade detached at 89e13a568d; expected worktree hook error from post-checkout.
- 2026-10-19 15:08 Step 1 done: graft 0985241d04 (parent 89e13a568d, tree == c162a7c953), branch upgrade/firefox. Main checkout still only `?? .scratch/`.
- 2026-10-19 15:10 Step 2 done: 2f38473cab, UPSTREAM_BASE hash matches expected.
- 2026-10-19 15:35 Step 3: planning docs restored from stash@{0} by path; adr/README.md 3-way apply conflicted (upstream ADR list 0007-0013 vs main's 0000-0006), resolved per plan: both entries in number order. ADR 0007 number collision with upstream recorded as a non-blocking question. 20 experiment tickets copied. Numbered handover trap list (traps 1-7) never committed; diary describes numbered traps only from ticket usage.
