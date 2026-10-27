# M1 progress

Plan: .scratch/firefox-upgrade/m1-plan.md
Base: origin/upgrade/firefox 3b9c862a57 (rebased 2026-10-28; was f0bb5fa14a)

## Steps

- [x] 0 Branch and baseline
- [x] 1 Summaries on-device only (MOB-5033): 8c078a133d, test 12873ed227, diary 581e76c537
- [x] 2 Lens, Quick Answers, ad blocker off (MOB-5034): c840022f08, 5eefefdb37, fa28866949, diary 581e76c537
- [ ] 3 PR A: verify.sh OK; ready, not pushed (Dario: no pushing yet)
- [x] 4 AI-free searching replaces the AI controls hub (MOB-5035): 24768096ed, 0b5b00720c, 8faaed984d, 8a661af4a3, test 110da2218b, diaries 9ff5653d74, e2090abe0d and the next commit; PR B: waiting on Dario to push (branch dc-mob-5035-ai-free-gates-firefox-ai, on top of PR A)
- [ ] 5 Feature configuration tests (MOB-5036): <commits>
- [ ] 6 Close-out; PR C: <number>

In progress: nothing (PR A and PR B ready locally; step 5 next)

## Device checks owed

- [ ] 07: supported device: summaries work; proxy shows no request to Mozilla's summarizer (mlpa-*.mozilla.global.ssl.fastly.net) or App Attest endpoints
- [ ] 07: unsupported device (or SKIP_APPLE_INTELLIGENCE): no summaries entry point anywhere
- [ ] 08: no Lens or Quick Answers entry point on the new tab page, address bar, image context menu
- [ ] 08: no "Block Ads" anywhere; Ecosia search ads show normally
- [ ] 09: AI-free on: no summaries or translations entry point; off: both work (supported device)
- [ ] 09: non-Ecosia provider: Summarize row (supported device) and Translation row in General settings; nothing hidden by an earlier AI-free value
- [ ] Before the first App Store Connect upload of the upgrade (latest ticket 24): check for ITMS-90683 (speech purpose string, Q1)
- [ ] 10: VPN off, Nova off

## Waiting on Dario

Nothing blocking. Q1 reframed (check at the first App Store Connect upload, not before merging PR A), Q2 to Q6 answered 2026-10-26. D1 to D3 are pre-decided unless vetoed. Dario: no pushing yet.

## Log

- 2026-10-25 18:07 Plan written from four read-only code searches plus own checks; per-channel values generated with the cached nimbus-fml binary (plan 3.1). Corrections to the searches: the ad-block list is not gated (plan 3.3), and the hub is unreachable in Ecosia's Settings (plan 3.4).
- 2026-10-25 18:07 Baseline verify.sh on f0bb5fa14a: OK (4999 tests, 4989 passed, 0 failed, 10 skipped; lint clean). Branch dc-mob-5033-m1-feature-flags from origin/upgrade/firefox; upstream tracking removed so a bare `git push` cannot reach upgrade/firefox.
- 2026-10-25 18:07 Step 1: YAMLs changed; generated release/beta/developer all false for hosted summarizer and App Attest. Entry-point trace in the diary. Simulator check (plan step 1.5) not done: it needs UI driving and is covered by Dario's device checks. The prepare-commit-msg hook adds `[MOB-5033]` from the branch name and keeps an existing `[MOB-5034]` prefix.
- 2026-10-25 18:09 Step 2: YAMLs changed (generated values all false); `reloadAdBlockerList()` guarded with two new ContentBlockerTests (in ClientTests, not EcosiaTests as the plan said: the flag mocks live there); speech key removed from Info.plist and 62 InfoPlist.strings, all plutil-clean. Bundled ad-block.json left for ticket 26. verify.sh started.
- 2026-10-25 18:19 verify.sh on 581e76c537: OK (5001 tests, 4991 passed, 0 failed, 10 skipped; both new ContentBlockerTests pass; lint clean). While waiting, the agent wrote "completed" notices into its own replies before the run had finished; it did not act on them. Trust only the log's `exit` line.
- 2026-10-26 15:28 Dario: no AI controls hub; Ecosia's AI-free searching toggle switches off summaries and translations; where the toggle is hidden, a summaries row instead. Plan section 4 and step 4 rewritten, ticket 09 and milestones.md updated.
- 2026-10-26 15:55 Step 4 on dc-mob-5035-ai-free-gates-firefox-ai: verify.sh OK (5012 tests, 5002 passed, 0 failed, 10 skipped; lint clean). A first run at 15:38 failed lint only (implicitly unwrapped optional in the new test), fixed.
- 2026-10-26 16:21 Dario: translations treated like summaries (Translation row where AI-free is not offered); keep models on disk; asked why a TestFlight build is needed: Q1 reframed, no longer blocks PR A. No pushing yet.
- 2026-10-26 (after 16:21) verify.sh hit ENOSPC (disk full, 155 MB free); Dario killed the run and freed space (Xcode's global DerivedData, simulators, build/m1-*): 41 GB free. A re-run failed in project generation (half-written SPM cache in Xcode's DerivedData for this worktree); once that cache was gone, verify.sh at 17:06: OK (5012 tests, 5002 passed, 0 failed, 10 skipped; lint clean). Run folders under build/ are now deleted after each result.
- 2026-10-27 12:26 Dario: update Jira and add both tests. Jira MOB-5035 rewritten (title, description, acceptance criteria). OnDeviceSummariesTests committed on PR A (12873ed227); PR B rebased onto it (unpushed; hashes in diary and progress updated).
- 2026-10-27 12:30 verify.sh: no simulator (Xcode auto-updated to 27.1 overnight, CoreSimulator 1171.7 < 1174.9.2). Dario ran the first-launch install.
- 2026-10-27 12:44 verify.sh on PR B: 2 failures. AuthTests clearsLoggedInImpactCache (known flaky, M0) and the new non-Ecosia-provider settings test (Settings resyncs the provider from the default engine). That test was removed; the case is covered by AIFreeSearchingSelectionTests.
- 2026-10-27 12:52 verify.sh on PR B: OK (5018 tests, 5008 passed, 0 failed, 10 skipped; lint clean).
