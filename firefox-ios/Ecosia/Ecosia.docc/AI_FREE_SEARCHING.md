# AI-free searching (MOB-4778)

Gates a native Settings toggle, `ECNOAI` cookie sync, Overviews exclusion, and NTP omnibox autorouting. Central hook: `AIFreeSearchingSelection.isActive` (Unleash flag **and** user toggle).

Flag: `mob_ios_ai_free_searching`. **Flag off → no behavior change.**

## Behavior

| Flag | Toggle | Overviews | NTP omnibox | `ECNOAI` |
| --- | --- | --- | --- | --- |
| Off | ignored | editable, unchanged | `ar=1` | omitted |
| On | default (never toggled) | editable | `ar=1` | omitted |
| On | enabled | forced off, not editable | `/search?q=…` (no `ar`) | `true` |
| On | explicitly off | editable again | `ar=1` | `false` |

Enabling AI-free while Overviews is on forces Overviews off (`ECAIO=false` via the existing search-settings cookie pipeline). Overviews cannot be turned back on until AI-free is off.

## Cookie contract

| Cookie | States | Web default if missing |
| --- | --- | --- |
| `ECNOAI` (new) | omit / `true` / `false` | treat as not opted into AI-free |
| `ECAIO` (existing) | always `true` or `false` | Overviews enabled |

`User.shared.aiFreeSearching` is `Bool?`: `nil` = never set (omit cookie); `true` / `false` = explicit (`ECNOAI=true` / `ECNOAI=false`). `received()` parses with `Bool(cookie.value)` and calls `setEnabled` when the flag is on. Absent cookie is **not** treated as a reset (cookie-store observer delivers the full jar, including before native injection).

`makeRequiredCookies` / `makeSearchSettingsObserverCookies` skip `ECNOAI` when the handler returns `nil`.

## Autorouting

`SearchProviderRouting.omniboxSearchURL` uses `autoRedirect: !AIFreeSearchingSelection.isActive`. `OmniboxSubmitRouting` calls that for plain NTP queries.

## Omnibox AI surfaces

When `AIFreeSearchingSelection.isActive`, `allowsOmniboxAI` is false:

- NTP omnibox **+** / upload button is hidden (`NTPSearchBarView.updateUploadButtonVisibility`). Refreshed on NTP appear, when showing the NTP omnibox, and on `searchSettingsChanged` (Settings is a form sheet, so `viewWillAppear` does not run on dismiss)
- AI Chat row in search suggestions is hidden (`shouldShowAIChatRow`)
- Chat-mode submit and attachment-to-chat routing fall back to plain search

## Test checklist

- [ ] Flag off: no Settings row, no `ECNOAI`, Overviews editable, `ar=1`
- [ ] Default: no `ECNOAI`; enable → `ECNOAI=true`; disable → `ECNOAI=false`
- [ ] `received()` round-trip (`true` / `false` / invalid)
- [ ] Enable AI-free with Overviews on → Overviews off, `ECAIO=false`, Overviews switch disabled
- [ ] Disable AI-free → Overviews editable
- [ ] NTP search has no `ar=1` when AI-free is on
- [ ] `searchSettingsChanged` fires on toggle
- [ ] Omnibox + button hidden when AI-free is on; visible again when off
- [ ] AI Chat suggestion row hidden when AI-free is on
