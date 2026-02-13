always consider this codebase is mixed with firefox-ios and our modifications

write comprehensive tests

keep `firefox-ios/Ecosia/Ecosia.docc/Ecosia.md` up to date

don't update the `/README.md` file as it is part of the `firefox-ios` core

name pull requests "[MOB-XXXX] {name of the feature}"
[MOB-XXXX] is the ticket reference, it should be provided as part of the PR/Ticket/Instructions
also add MOB-XXXX with the correct ticket name into the branch name so we can link tickets and branches and pull requests by this identifier
issues that don't reference a ticket should use `NOTICKET` in the PR name and `noticket` in the branch name


consider a architecture decision record based on this template
https://github.com/joelparkerhenderson/architecture-decision-record/tree/main/locales/en/templates/decision-record-template-of-the-madr-project is a good template
request other considerations needed to implement a feature
document unsolved issues in the architecture decision record
ADRs should be stored in `docs/decisions/` and the readme `docs/decisions/README.md` should be updated to have an up-to-date list
`docs/decisions/0001-swiftlint-configuration-for-upstream-fork.md` is a good name for the ADR

consider adding readme.md files into folders that are created or touched heavily during feature development so that folders represent features and have some documentation

## Commenting Guidelines for Ecosia Code in Firefox

when modifying Firefox code for Ecosia customizations, follow these commenting conventions:

1. **One-liner Comments**: Use `//` for introducing new code or brief explanations.
   ```swift
   // Ecosia: Update appversion predicate
   let appVersionPredicate = (appVersionString?.contains("Ecosia") ?? false) == true
   ```

2. **Block Comments**: Use `/* */` when commenting out existing Firefox code for easier readability and conflict resolution.
   ```swift
   /* Ecosia: Update appversion predicate
   let appVersionPredicate = (appVersionString?.contains("Firefox") ?? false) == true
   */
   let appVersionPredicate = (appVersionString?.contains("Ecosia") ?? false) == true
   ```

## User Scripts

User Scripts (JavaScript injected into WKWebView) are compiled, concatenated, and minified using webpack

when adding or editing User Scripts in `/Client/Frontend/UserContent/UserScripts/`, recompile them by running `npm run build` in the project root

the compiled outputs are checked into the repository at `/Client/Assets/` with names like `AllFramesAtDocumentEnd.js`, `MainFrameAtDocumentStart.js`, etc.

## Ecosia Framework Structure

the Ecosia Framework (`firefox-ios/Ecosia/`) is a wrapper for Ecosia-specific implementation and logic

some Ecosia codebase still lives under `Client/Ecosia`, but new Ecosia-specific code should be added to the Ecosia Framework when possible

## Translations

translations are managed via Transifex

when adding new strings, add them to `Client/Ecosia/L10N/en.lproj/Ecosia.strings`

## Snapshot Testing

use `SnapshotTestHelper` for UI snapshot testing

snapshot tests support multiple themes, devices, and localizations

reference images are compared to detect unintended UI changes

see `SNAPSHOT_TESTING_WIKI.md` for more details

## Running Tests from Command Line

### Project Structure

The project uses `firefox-ios/Client.xcodeproj` with the **Ecosia** scheme for builds and tests.

### Available Test Targets

- `ClientTests` - Firefox and Ecosia client tests (including wallpaper tests)
- `EcosiaTests` - Ecosia-specific unit tests
- `EcosiaSnapshotTests` - Ecosia UI snapshot tests
- `AccountTests` - Account-related tests
- `StorageTests` - Storage layer tests
- `SyncTests` - Sync functionality tests

### List Available Schemes and Targets

```bash
xcodebuild -project firefox-ios/Client.xcodeproj -list
```

### Running All Tests

```bash
xcodebuild test \
  -project firefox-ios/Client.xcodeproj \
  -scheme Ecosia \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

### Running Specific Test Target

```bash
# Run all EcosiaTests
xcodebuild test \
  -project firefox-ios/Client.xcodeproj \
  -scheme Ecosia \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:EcosiaTests

# Run all ClientTests
xcodebuild test \
  -project firefox-ios/Client.xcodeproj \
  -scheme Ecosia \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ClientTests
```

### Running Specific Test Class

```bash
# Run wallpaper-related tests
xcodebuild test \
  -project firefox-ios/Client.xcodeproj \
  -scheme Ecosia \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ClientTests/WallpaperCodableTests
```

### Running Specific Test Method

```bash
xcodebuild test \
  -project firefox-ios/Client.xcodeproj \
  -scheme Ecosia \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ClientTests/WallpaperCodableTests/testEncodingWithBundledAsset
```

### List Available Simulators

```bash
xcrun simctl list devices available | grep iPhone
```

### Tips

- Use `-only-testing` to run specific test targets, classes, or methods
- Use `-skip-testing` to exclude specific tests
- The scheme is **Ecosia**, not ClientTests or EcosiaTests (those are test targets, not schemes)
- Test results are saved to `~/Library/Developer/Xcode/DerivedData/Client-*/Logs/Test/`
- If you get "database is locked" errors, ensure no other builds are running in Xcode
- Use `| tee /tmp/test-output.txt` to save output to a file while viewing it

### Known Issues

- Command-line test runs may fail with "Unable to find module dependency" errors for Shared, Client, or Common modules
- This appears to be related to the complex build configuration with multiple targets and BrowserKit integration
- **Workaround**: Run tests from within Xcode.app using the Test Navigator (⌘6) or Product → Test (⌘U)
- Tests run successfully from Xcode's UI but may have issues from command line without proper DerivedData setup

### Running Tests from Xcode

The most reliable way to run tests:

1. Open `firefox-ios/Client.xcodeproj` in Xcode
2. Select the **Ecosia** scheme
3. Choose a simulator (e.g., iPhone 17 Pro)
4. Open Test Navigator (⌘6)
5. Run all tests (⌘U) or click the ▶︎ button next to specific test classes/methods
