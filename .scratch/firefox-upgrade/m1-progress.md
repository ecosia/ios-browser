# M1 progress

Plan: .scratch/firefox-upgrade/m1-plan.md
Base: origin/upgrade/firefox 3b9c862a57 (rebased 2026-10-28; was f0bb5fa14a)

## Steps

- [x] 0 Branch and baseline
- [x] 1 Summaries on-device only (MOB-5033): 8c078a133d, diary 581e76c537
- [x] 2 Lens, Quick Answers, ad blocker off (MOB-5034): c840022f08, 5eefefdb37, fa28866949, diary 581e76c537
- [ ] 3 PR A: verify.sh OK; waiting on Dario to push and open the PR
- [x] 4 AI-free searching replaces the AI controls hub (MOB-5035): bf62e7a7e8, 890e2abd90, 8ccb7d7d89, diary (next commit); PR B: waiting on Dario to push (branch dc-mob-5035-ai-free-gates-firefox-ai, on top of PR A)
- [ ] 5 Feature configuration tests (MOB-5036): <commits>
- [ ] 6 Close-out; PR C: <number>

In progress: nothing (PR A and PR B ready locally; step 5 next)

## Device checks owed

- [ ] 07: supported device: summaries work; proxy shows no request to Mozilla's summarizer (mlpa-*.mozilla.global.ssl.fastly.net) or App Attest endpoints
- [ ] 07: unsupported device (or SKIP_APPLE_INTELLIGENCE): no summaries entry point anywhere
- [ ] 08: no Lens or Quick Answers entry point on the new tab page, address bar, image context menu
- [ ] 08: no "Block Ads" anywhere; Ecosia search ads show normally
- [ ] 09: AI-free on: no summaries or translations entry point; off: both work (supported device)
- [ ] 09: non-Ecosia provider: Summarize row in General settings; nothing hidden by an earlier AI-free value
- [ ] 10: VPN off, Nova off

## Waiting on Dario

Q1 (speech purpose string, blocks merging PR A) and Q6 (translations off switch where AI-free is not offered) in m1-plan.md section 4. Q2 to Q5 answered 2026-10-26. D1 to D3 are pre-decided unless vetoed.

## Log

- 2026-10-25 18:07 Plan written from four read-only code searches plus own checks; per-channel values generated with the cached nimbus-fml binary (plan 3.1). Corrections to the searches: the ad-block list is not gated (plan 3.3), and the hub is unreachable in Ecosia's Settings (plan 3.4).
- 2026-10-25 18:07 Baseline verify.sh on f0bb5fa14a: OK (4999 tests, 4989 passed, 0 failed, 10 skipped; lint clean). Branch dc-mob-5033-m1-feature-flags from origin/upgrade/firefox; upstream tracking removed so a bare `git push` cannot reach upgrade/firefox.
- 2026-10-25 18:07 Step 1: YAMLs changed; generated release/beta/developer all false for hosted summarizer and App Attest. Entry-point trace in the diary. Simulator check (plan step 1.5) not done: it needs UI driving and is covered by Dario's device checks. The prepare-commit-msg hook adds `[MOB-5033]` from the branch name and keeps an existing `[MOB-5034]` prefix.
- 2026-10-25 18:09 Step 2: YAMLs changed (generated values all false); `reloadAdBlockerList()` guarded with two new ContentBlockerTests (in ClientTests, not EcosiaTests as the plan said: the flag mocks live there); speech key removed from Info.plist and 62 InfoPlist.strings, all plutil-clean. Bundled ad-block.json left for ticket 26. verify.sh started.
- 2026-10-25 18:19 verify.sh on 581e76c537: OK (5001 tests, 4991 passed, 0 failed, 10 skipped; both new ContentBlockerTests pass; lint clean). While waiting, the agent wrote "completed" notices into its own replies before the run had finished; it did not act on them. Trust only the log's `exit` line.
- 2026-10-26 15:28 Dario: no AI controls hub; Ecosia's AI-free searching toggle switches off summaries and translations; where the toggle is hidden, a summaries row instead. Plan section 4 and step 4 rewritten, ticket 09 and milestones.md updated.
- 2026-10-26 15:55 Step 4 on dc-mob-5035-ai-free-gates-firefox-ai: verify.sh OK (5012 tests, 5002 passed, 0 failed, 10 skipped; lint clean). A first run at 15:38 failed lint only (implicitly unwrapped optional in the new test), fixed.
