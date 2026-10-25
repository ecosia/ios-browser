# M1 progress

Plan: .scratch/firefox-upgrade/m1-plan.md
Base: origin/upgrade/firefox f0bb5fa14a

## Steps

- [x] 0 Branch and baseline
- [x] 1 Summaries on-device only (MOB-5033): db825ea6c5, diary 4dc90a8453
- [x] 2 Lens, Quick Answers, ad blocker off (MOB-5034): c0f2adb56d, 70b6e630e4, ebb70c8fea, diary 4dc90a8453
- [ ] 3 PR A: verify.sh OK; waiting on Dario to push and open the PR
- [ ] 4 AI controls hub (MOB-5035): <commits>; PR B: <number>
- [ ] 5 Feature configuration tests (MOB-5036): <commits>
- [ ] 6 Close-out; PR C: <number>

In progress: nothing (PR A ready locally; step 4 waits on Q2 to Q5)

## Device checks owed

- [ ] 07: supported device: summaries work; proxy shows no request to Mozilla's summarizer (mlpa-*.mozilla.global.ssl.fastly.net) or App Attest endpoints
- [ ] 07: unsupported device (or SKIP_APPLE_INTELLIGENCE): no summaries entry point anywhere
- [ ] 08: no Lens or Quick Answers entry point on the new tab page, address bar, image context menu
- [ ] 08: no "Block Ads" anywhere; Ecosia search ads show normally
- [ ] 10: VPN off, Nova off

## Waiting on Dario

Q1 to Q5 in m1-plan.md section 4. Q1 blocks merging PR A (not writing it); Q2 to Q5 block step 4. D1 to D3 are pre-decided unless vetoed.

## Log

- 2026-10-25 18:07 Plan written from four read-only code searches plus own checks; per-channel values generated with the cached nimbus-fml binary (plan 3.1). Corrections to the searches: the ad-block list is not gated (plan 3.3), and the hub is unreachable in Ecosia's Settings (plan 3.4).
- 2026-10-25 18:07 Baseline verify.sh on f0bb5fa14a: OK (4999 tests, 4989 passed, 0 failed, 10 skipped; lint clean). Branch dc-mob-5033-m1-feature-flags from origin/upgrade/firefox; upstream tracking removed so a bare `git push` cannot reach upgrade/firefox.
- 2026-10-25 18:07 Step 1: YAMLs changed; generated release/beta/developer all false for hosted summarizer and App Attest. Entry-point trace in the diary. Simulator check (plan step 1.5) not done: it needs UI driving and is covered by Dario's device checks. The prepare-commit-msg hook adds `[MOB-5033]` from the branch name and keeps an existing `[MOB-5034]` prefix.
- 2026-10-25 18:09 Step 2: YAMLs changed (generated values all false); `reloadAdBlockerList()` guarded with two new ContentBlockerTests (in ClientTests, not EcosiaTests as the plan said: the flag mocks live there); speech key removed from Info.plist and 62 InfoPlist.strings, all plutil-clean. Bundled ad-block.json left for ticket 26. verify.sh started.
- 2026-10-25 18:19 verify.sh on 4dc90a8453: OK (5001 tests, 4991 passed, 0 failed, 10 skipped; both new ContentBlockerTests pass; lint clean). While waiting, the agent wrote "completed" notices into its own replies before the run had finished; it did not act on them. Trust only the log's `exit` line.
