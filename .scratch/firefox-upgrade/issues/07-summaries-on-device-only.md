# 07: Summaries on-device only

**Jira:** [MOB-5033](https://ecosia.atlassian.net/browse/MOB-5033)
**Milestone:** M1 Feature configuration
**Status:** ready-for-agent
**Blocked by:** 02

## What to build

Page summaries run only on-device (Apple Intelligence through `FoundationModelsSummarizer` in `BrowserKit/Sources/SummarizeKit`). No page content is sent to Mozilla's hosted summarizer, and devices that cannot summarize on-device show no summaries entry point at all: no shake gesture, no toolbar or menu entry, no toggle in the AI controls hub.

On the 155.1 branch, the hosted path is currently **on** for beta and developer:

- `firefox-ios/nimbus-features/hostedSummarizerFeature.yaml`: `enabled: true` on beta and developer
- `firefox-ios/nimbus-features/summarizerAppAttestAuthFeature.yaml`: `enabled: true` on beta and developer (App Attest auth exists only for the hosted path)

Set both to `false` on every channel, with `release` listed explicitly and a `# Ecosia:` reason. Then trace every summaries entry point to confirm it is gated on on-device availability (see `PrefsKeys.appleIntelligenceAvailable` / `cannotRunAppleIntelligence` in `BrowserKit/Sources/Shared/Prefs.swift`), not on "on-device or hosted".

## Acceptance criteria

- [x] Hosted summarizer and App Attest auth are off on release, beta and developer, verified in the generated `FxNimbus.swift` for each channel (`bin/nimbus-fml.sh`), not only by reading YAML (generated release, beta and developer all false, 2026-10-25)
- [x] On a device without Apple Intelligence (or with the `SKIP_APPLE_INTELLIGENCE` launch argument), no summaries entry point is visible anywhere (simulator 2026-10-27, EcosiaBeta BetaDebug, launched with SKIP_APPLE_INTELLIGENCE; shake covered by OnDeviceSummariesTests)
- [x] On a supported device, summaries work, and network inspection shows no request to Mozilla's summarizer endpoints (simulator 2026-10-27, EcosiaBeta BetaDebug: "Summarised by Apple Intelligence"; the simulator log shows no app connection during the summary and none ever to mlpa-* or App Attest)
- [x] Diary entry written, listing every entry point and its gate
