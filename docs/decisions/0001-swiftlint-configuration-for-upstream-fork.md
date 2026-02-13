# SwiftLint Configuration for Upstream Firefox Fork

* Status: accepted
* Deciders: Ecosia iOS Team
* Date: 2026-02-03

## Context and Problem Statement

The Ecosia iOS browser is a fork of Mozilla's Firefox iOS browser. As a fork, we regularly merge upstream changes from Firefox to stay up-to-date with security patches, features, and improvements. This creates a challenge with linting: how do we maintain code quality in our codebase while avoiding conflicts when merging upstream changes?

## Decision Drivers

* Need to maintain code quality in Ecosia-specific code
* Need to minimize merge conflicts when incorporating Firefox upstream changes
* Want to use SwiftLint's `--fix` option for automatic code formatting
* Firefox core codebase has existing lint violations that are outside our control

## Considered Options

* **Option 1**: Fix all Firefox upstream lint issues in our fork
* **Option 2**: Exclude Firefox core files from linting entirely
* **Option 3**: Lint all files but do not auto-fix Firefox core files (current approach)

## Decision Outcome

Chosen option: **Option 3 - Lint all files but do not auto-fix Firefox core files**, because it allows us to maintain visibility of code quality across the entire codebase while avoiding merge conflicts that would arise from auto-fixing upstream code.

To ensure we can work with the file, the JSON is pretty printed and json-key-sorted

```shell
python3 -m json.tool --sort-keys swiftlint_baseline.json > swiftlint_baseline.tmp && mv swiftlint_baseline.tmp swiftlint_baseline.json
```

### Positive Consequences

* Merge conflicts with upstream Firefox are minimized
* Ecosia-specific code can still benefit from `swiftlint --fix` automatic corrections
* Lint warnings in Firefox core files remain visible for awareness
* Easier to stay synchronized with Mozilla's upstream changes

### Negative Consequences

* Firefox core files retain existing lint violations
* Currently no automated way to selectively apply `--fix` only to Ecosia team files
* Manual discipline required to not accidentally auto-fix Firefox files

## Pros and Cons of the Options

### Option 1: Fix all Firefox upstream lint issues

* Good, because it would result in a completely clean lint output
* Good, because it enforces consistent code style across the entire codebase
* Bad, because it would cause significant merge conflicts on every upstream merge
* Bad, because it requires ongoing effort to re-fix issues after each upstream sync

### Option 2: Exclude Firefox core files from linting entirely

* Good, because it eliminates noise from Firefox lint violations
* Good, because it focuses lint output only on Ecosia code
* Bad, because we lose visibility into code quality issues in files we may need to modify
* Bad, because it could mask potential issues when Ecosia code interacts with Firefox code

### Option 3: Lint all files but do not auto-fix Firefox core files

* Good, because it maintains visibility of all lint issues
* Good, because it minimizes merge conflicts with upstream
* Good, because Ecosia code can still be auto-fixed
* Bad, because there is currently no built-in SwiftLint mechanism to selectively apply `--fix`

## Open Issues

* **Selective auto-fix**: Currently, there is no straightforward way to tell SwiftLint to `--fix` only files changed by the Ecosia team while leaving Firefox core files untouched. A potential solution would involve:
  - Creating a script that identifies Ecosia-owned files (possibly based on file paths or git history)
  - Running `swiftlint --fix` only on those specific files
  - Integrating this into the CI/CD pipeline or pre-commit hooks


for some reason running `swiftlint --fix firefox-ios/Client/Ecosia/Extensions/AppSettingsTableViewController+Ecosia.swift` for instance would not work out of the box:
```
➜ swiftlint  firefox-ios/Client/Ecosia/Extensions/AppSettingsTableViewController+Ecosia.swift 
\warning: 'redundant_optional_initialization' has been renamed to 'implicit_optional_initialization' and will be completely removed in a future release.
warning: 'operator_whitespace' has been renamed to 'function_name_whitespace' and will be completely removed in a future release.
warning: Found a configuration for 'line_length' rule, but it is not present in 'only_rules'.
Linting Swift files at paths firefox-ios/Client/Ecosia/Extensions/AppSettingsTableViewController+Ecosia.swift
Linting 'AppSettingsTableViewController+Ecosia.swift' (1/1)
/Users/falkorichter/Documents/ios-browser-2026/firefox-ios/Client/Ecosia/Extensions/AppSettingsTableViewController+Ecosia.swift:143:25: warning: Vertical Parameter Alignment on Call Violation: Function parameters should be aligned vertically if they're in multiple lines in a method call (vertical_parameter_alignment_on_call)
/Users/falkorichter/Documents/ios-browser-2026/firefox-ios/Client/Ecosia/Extensions/AppSettingsTableViewController+Ecosia.swift:144:25: warning: Vertical Parameter Alignment on Call Violation: Function parameters should be aligned vertically if they're in multiple lines in a method call (vertical_parameter_alignment_on_call)
/Users/falkorichter/Documents/ios-browser-2026/firefox-ios/Client/Ecosia/Extensions/AppSettingsTableViewController+Ecosia.swift:146:25: warning: Vertical Parameter Alignment on Call Violation: Function parameters should be aligned vertically if they're in multiple lines in a method call (vertical_parameter_alignment_on_call)
/Users/falkorichter/Documents/ios-browser-2026/firefox-ios/Client/Ecosia/Extensions/AppSettingsTableViewController+Ecosia.swift:147:25: warning: Vertical Parameter Alignment on Call Violation: Function parameters should be aligned vertically if they're in multiple lines in a method call (vertical_parameter_alignment_on_call)
/Users/falkorichter/Documents/ios-browser-2026/firefox-ios/Client/Ecosia/Extensions/AppSettingsTableViewController+Ecosia.swift:148:25: warning: Vertical Parameter Alignment on Call Violation: Function parameters should be aligned vertically if they're in multiple lines in a method call (vertical_parameter_alignment_on_call)
Done linting! Found 5 violations, 0 serious in 1 file.

➜ swiftlint --fix firefox-ios/Client/Ecosia/Extensions/AppSettingsTableViewController+Ecosia.swift
warning: 'redundant_optional_initialization' has been renamed to 'implicit_optional_initialization' and will be completely removed in a future release.
warning: 'operator_whitespace' has been renamed to 'function_name_whitespace' and will be completely removed in a future release.
warning: Found a configuration for 'line_length' rule, but it is not present in 'only_rules'.
Correcting Swift files at paths firefox-ios/Client/Ecosia/Extensions/AppSettingsTableViewController+Ecosia.swift
Correcting 'AppSettingsTableViewController+Ecosia.swift' (1/1)
Done correcting 1 file!
```
It mentions `Done correcting 1 file!` but the file has not been fixed and had to be fixed manually.

## Links

* [SwiftLint Configuration](.swiftlint.yml) - Current SwiftLint rules and exclusions
* [Firefox iOS Repository](https://github.com/mozilla-mobile/firefox-ios) - Upstream repository
* Confluence: NAPPS-5 - [SwiftLint Configuration for Upstream Firefox Fork](https://ecosia.atlassian.net/wiki/spaces/DEV/pages/4408836232/2026-02-03+-+ADR-NAPPS-5+SwiftLint+Configuration+for+Upstream+Firefox+Fork)
