always consider this codebase is mixed with firefox-ios and our modifications

write comprehensive tests

keep `firefox-ios/Ecosia/Ecosia.docc/Ecosia.md` up to date

don't update the `/README.md` file as it is part of the `firefox-ios` core

name pull requests "[MOB-XXXX] {name of the feature}"
[MOB-XXXX] is the ticket reference, it should be provided as part of the PR/Ticket/Instructions
also add MOB-XXXX with the correct ticket name into the branch name so we can link tickets and branches and pull requests by this identifier
issues that don't reference a ticket should use `NOTICKET` in the PR name and `noticket` in the branch name


consider a architecture descision record based on this template
https://github.com/joelparkerhenderson/architecture-decision-record/tree/main/locales/en/templates/decision-record-template-of-the-madr-project is a good template
request other considerations that to implement a feature
document unsolved issues in the architecture decision record
ADRs should be stored in  `docs/decisions/` and the readme `docs/decisions/README.md` should be updated to have an up to date list
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

## Building and Dependencies

ensure SwiftLint is installed and used for linting: `brew install swiftlint`

after cloning or when updating dependencies, run `./bootstrap.sh` to install Node.js dependencies, build user scripts, and update content blockers

the project uses Swift Package Manager (SPM). If you encounter dependency issues, try: Xcode -> File -> Packages -> Reset Package Caches

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

after Firefox upgrades, run `python3 ecosify-strings.py firefox-ios` to rebrand Mozilla strings

## Snapshot Testing

use `SnapshotTestHelper` for UI snapshot testing

snapshot tests support multiple themes, devices, and localizations

reference images are compared to detect unintended UI changes

see `SNAPSHOT_TESTING_WIKI.md` for more details
