# M1 progress

Plan: .scratch/firefox-upgrade/m1-plan.md
Base: origin/upgrade/firefox 3b9c862a57 (rebased 2026-10-28; was f0bb5fa14a)

## Steps

- [x] 0 Branch and baseline
- [x] 1 Summaries on-device only (MOB-5033): 8c078a133d, test 12873ed227, diary 581e76c537
- [x] 2 Lens, Quick Answers, ad blocker off (MOB-5034): c840022f08, 5eefefdb37, fa28866949, diary 581e76c537
- [ ] 3 PR A: verify.sh OK; rebased onto upgrade/firefox 3b9c862a57 on 2026-10-28; ready, not pushed (Dario: no pushing yet)
- [x] 4 AI-free searching replaces the AI controls hub (MOB-5035): ed090cca0e, 5c3a25fdd9, a86b97c1e1, a8cc753ac5, test 29852b107e, diaries 7a04848dc7, 073f54a48a and the next commit; PR B: waiting on Dario to push (branch dc-mob-5035-ai-free-gates-firefox-ai, on top of PR A)
- [ ] 5 Feature configuration tests (MOB-5036): <commits>
- [ ] 6 Close-out; PR C: <number>

In progress: nothing (PR A and PR B ready locally; step 5 next)

## Device checks owed

- [x] 07: supported device: summaries work, and no request to Mozilla's summarizer (mlpa-*.mozilla.global.ssl.fastly.net) or App Attest (simulator 2026-10-27, EcosiaBeta BetaDebug: "Summarised by Apple Intelligence"; the simulator's stored network log shows no app connection during the summary; the app log, which records every Remote Settings request since this simulator was set up, never mentions mlpa)
- [x] 07: unsupported device (or SKIP_APPLE_INTELLIGENCE): no summaries entry point anywhere (simulator 2026-10-27, EcosiaBeta BetaDebug, 27936e36f6, launched with SKIP_APPLE_INTELLIGENCE: no summarize button in the address bar, no "Summarise Page" in the menu or More, none in reader view, no "Page Summaries" row with DuckDuckGo; shake not testable in the pane, covered by OnDeviceSummariesTests)
- [x] 08: no Lens or Quick Answers entry point on the new tab page, address bar, image context menu (simulator 2026-10-27, EcosiaBeta BetaDebug, e4a2de231d)
- [x] 08: no "Block Ads" anywhere; Ecosia search ads show normally (simulator 2026-10-27, EcosiaBeta BetaDebug, e4a2de231d)
- [x] 09: AI-free on: no summaries or translations entry point; off: both work (supported device) (simulator 2026-10-27, EcosiaBeta BetaDebug, e4a2de231d). Bug found and fixed (27936e36f6): switching the search engine back to Ecosia while AI-free was on left the toolbar's translate and summarize buttons until the next page load
- [x] 09: non-Ecosia provider: Summarize row (supported device) and Translation row in General settings; nothing hidden by an earlier AI-free value (simulator 2026-10-27, EcosiaBeta BetaDebug, e4a2de231d)
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
- 2026-10-27 13:00 verify.sh on PR A alone (12873ed227): OK (5004 tests, 4994 passed, 0 failed, 10 skipped; lint clean).
- 2026-10-27 19:40 Simulator checks (Claude Desktop iOS Simulator pane, dedicated simulator "iPhone 17 M1 checks", EcosiaBeta BetaDebug of e4a2de231d). The simulator counts as a supported device (on-device summaries via the Mac's Apple Intelligence), so 07's unsupported-device check still needs an older device or SKIP_APPLE_INTELLIGENCE; the proxy checks still need Proxyman. Side effects: one ad click (sportler.com) from a tap during page load; search region briefly changed to Latvia (not by Claude) and restored to Italy; end state Ecosia, Italy, AI-free off.
- 2026-10-27 20:00 Dario: fix the bug. BrowserAIRefresh (toggle and engine picker share it; the picker refreshes only when blocksBrowserAI changes), 4 tests. verify.sh on PR B: OK (5022 tests, 5012 passed, 0 failed, 10 skipped; lint clean). Fix confirmed on the simulator; end state Ecosia, Italy, AI-free off.
- 2026-10-27 22:20 07 unsupported-device check on the simulator with `xcrun simctl launch … SKIP_APPLE_INTELLIGENCE` (stored appleIntelligenceAvailableKey went false a few seconds after launch): passed. VPN has no user-facing entry point in 157 (flag only on the debug feature-flags screen); Nova changes styling only. End state: relaunched without the argument (available again), Ecosia, Italy, AI-free off. Network checks (07, 08) need Proxyman's system proxy on, which Dario turns on.
- 2026-10-27 22:40 Dario: finalise 5033 and 5035 locally. Network checks done without a proxy. 07: summary run at 22:30:50 to 22:31:08 with `log show` over the simulator's stored network log: no app connection in that window, none to mlpa-* or App Attest. 08: the app's Firefox.log records every Remote Settings URL (Rust viaduct) since this simulator's first launch at 16:26; tracking-protection-lists-ios never appears, and WebKit's rule store has only the 8 Disconnect lists. origin/upgrade/firefox (M0 sign-off, #1362) merged into PR A (2aa6573f34), PR A into PR B. Acceptance criteria in issues 07, 08 and 09 ticked.
- 2026-10-28 Dario: fast-forward upgrade/firefox to origin (3b9c862a57: M0 sign-off #1362 and main sync #1371) and rebase both branches onto it instead of merging. PR A rebased (one diary conflict, M0 sign-off entry kept before 07), then PR B onto PR A (progress-log conflicts only). The merge commits 2aa6573f34 and 55f43fa728 from 2026-10-27 no longer exist. Commit hashes in the plan, progress, diary and issues updated to the rebased ones.
- 2026-10-28 verify.sh after the rebase, both runs exit 2 (tests) on flakes outside these PRs. PR B (b7932105d0): only EcosiaAIChatButtonThemeTests.testIntegrationWithButton and FeedbackThemeTests.testIntegrationWithFeedbackView failed, the two Xcode 27 failures verify.sh skips; its skip list was empty in that run (the test log has no -skip-testing), likely because `xcodebuild -version | head -1` under pipefail can fail when head closes the pipe early (not reproduced in 30 tries). PR A (3338056a6a): only AuthTests testRetrieveStoredCredentials_withFailureAfterPreviousLogin_clearsLoggedInImpactCacheAndWasLoggedIn failed, the M0 flake; alone it failed 1 of 5 runs. Every other test passed in both runs; swiftlint --strict clean on both.
