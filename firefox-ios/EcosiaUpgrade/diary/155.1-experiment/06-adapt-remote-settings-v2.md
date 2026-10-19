# 06: Adapt to Remote Settings v2

**What to build:** Ecosia's search-engine remote configuration (provider, selector, icon fetching, and the AI/summarizer remote config it was renamed alongside) continues to fetch and apply correctly under upstream's new Remote Settings v2 plumbing.

**Blocked by:** 02

**Status:** done

- [x] All four Application Services customization files compile against the new remote-settings types
- [x] The renamed remote-config file's Ecosia customization is carried over completely, not just recreated as a stub
- [~] The default search-engine identity characterization test (ticket 01) still passes, confirming the identity resolution this ticket touches didn't regress — *cannot be executed (549 unmerged files); verified by inspection instead, see below*

## Comments

### All four AS files: exactly upstream + exactly Ecosia's delta

The four auto-merged cleanly, and each one's Ecosia customization survived **verbatim**, matching its intent diff line for line. Diffing each merged file against `firefox-v155.1` shows *only* the Ecosia hunk and nothing else:

| File | Ecosia delta |
| --- | --- |
| `ASRemoteSettingsCollection.swift` | `makeClient()` uses `resolveOptional()` + `guard … else { return nil }` |
| `ASSearchEngineIconDataFetcher.swift` | same, in `init?` |
| `ASSearchEngineProvider.swift` | `if selector == nil, let profile: Profile = …resolveOptional()` |
| `ASSearchEngineSelector.swift` | same, with `completion(nil, nil)` bail-out on a background thread |

All four are one pattern: replace `AppContainer.shared.resolve()` (which traps) with `resolveOptional()` and a safe bail-out, because `AppContainer` is briefly empty during unit-test `setUp`.

**Type compatibility is guaranteed, not assumed:** every Ecosia line substitutes only the resolve call on a line upstream still has, and keeps using `profile.remoteSettingsService` / `ASSearchEngineSelector(service:)` exactly as upstream's adjacent code does. No symbol is referenced that upstream does not itself reference in place.

Two type changes upstream made that could have broken Ecosia's lines, both checked:

- `selector` is now `ASSearchEngineSelectorProtocol?` — `ASSearchEngineSelector` conforms, so Ecosia's assignment is fine.
- `ASAIRemoteConfig.init` takes `RemoteSettingsClientProtocol?` while Ecosia's `makeClient()` returns the concrete `RemoteSettingsClient?` — `RemoteSettingsClient: RemoteSettingsClientProtocol` in the generated Rust-components code, so it converts.

Also confirmed Ecosia's `ASSearchEngineProvider` comment is still accurate at 155.1: when both `selector` and `profile` are nil, `getUnorderedBundledEnginesFor` still has `guard let iconPopulator = iconDataFetcher, let selector else { … completion([]) }`, so the nil-selector path stays safe rather than trapping.

### The renamed file — Ecosia's customization was *retired*, not dropped

`ASSummarizerRemoteConfig.swift` → **`ASAIRemoteConfig.swift`**. Git detected the rename, so this arrived as a proper `UU` rename conflict rather than a silent delete-plus-new-file; Ecosia's side was never at risk of being lost.

The customization itself is now **obsolete**, and this needs stating clearly because it reads like a dropped customization:

- Ecosia's change was `init?(profile: Profile? = AppContainer.shared.resolveOptional())` + `guard let profile else { return nil }`, so the initialiser would not trap when the container was empty.
- At 155.1 the class **no longer resolves `Profile` at all** — upstream removed both the `profile` and `service` properties and switched to injecting `rsClient`, with a non-failable `init`.
- The AppContainer safety Ecosia wanted is still there, one level down and more robustly: the default argument calls `ASRemoteSettingsCollection.summarizerModelsConfig.makeClient()`, and *that* is the Ecosia-customized method returning `nil` instead of trapping.

So the intent is fully preserved while the code is not. Took upstream's initialiser, which leaves `ASAIRemoteConfig.swift` **byte-identical to `firefox-v155.1`** — deliberately: a pristine file has zero conflict surface next upgrade. No `// Ecosia:` marker was added, precisely so the next intent-diff run does not report a customization that no longer exists.

### AC 3 — verified structurally rather than by running

Ticket 01's identity test cannot run (549 unmerged files). It is nonetheless safe from this ticket's changes, for a concrete reason: its subject is **`EcosiaSearchEngineProvider`**, not the `ASSearchEngineProvider` this ticket touches. `SearchEngineProviderFactory` still carries Ecosia's substitution intact —

```swift
/* Ecosia: … static let defaultSearchEngineProvider: SearchEngineProvider = ASSearchEngineProvider() */
static var defaultSearchEngineProvider: SearchEngineProvider {
    if CustomSearchProviderFeatureFlag.isEnabled { return CuratedSearchEngineProvider() }
    return EcosiaSearchEngineProvider()
}
```

— so upstream's provider is never reached in production. Marked `[~]` rather than `[x]`: not executed.

### Bonus: upstream now tests the predicate ticket 01 had to replicate

Resolving `OpenSearchEngineTests.swift` (Ecosia-touched, 1 conflict) brought in upstream's four new `test_isGoogleEngine_*` cases, covering exactly the identity check ticket 01 documents by hand — including the `"googler"` false-positive guard. **After ticket 10, ticket 01's hand-rolled `matchesUpstreamGoogleEngineCheck` helper can be deleted in favour of calling `isGoogleEngine` directly**, now that upstream owns the coverage.

Ecosia had deleted upstream's two `test_trendingURLForEngine_*` tests, presumably because the API did not exist for it at 147.2. It does at 155.1 (`trendingTemplate`, `trendingURLForEngine()`, `TrendingSearchEngine` conformance are all present), so that removal's rationale had expired and upstream's block was restored.

One Ecosia customization in that file was checked and **kept because it is still required**: `SimpleFileAccessor`. Upstream uses `MockFiles(rootPath:)`, but the `MockFiles` visible to the `ClientTests` target (`ClientTests/Mocks/MockProfile.swift`) declares `init()` with no arguments — the `rootPath:` variant lives in `StorageTests`, outside this target's sources. `FileAccessor` supplies default implementations via a public extension, so Ecosia's one-property conformance compiles.

### Other files in this area

- `RemoteDataTypeTests.swift` — `UD`, Ecosia had deleted all 107 lines (tests for `PasswordRuleRecord` / `ContentBlockingListRecord` fixture loading). Removal preserved per the glossary. No Ecosia assertions existed to port — Ecosia deleted rather than modified. Reason unrecorded; note that upstream also deleted `ContentBlockingListRecord.swift` itself, which is consistent with the removal.
- `RemoteSettingsFetchConfig.swift` and `ContentBlockingListRecord.swift` were deleted upstream and were **not** Ecosia-touched, so their deletions needed no decision.
- `SearchEngineSelectionMiddlewareTests.swift` — deferred, see the unassigned list. Its 3 conflicts are about the `StoreTestUtility` API, not remote settings.
