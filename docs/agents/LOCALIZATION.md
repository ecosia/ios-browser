# Localization

## String Management

- Localization keys are organized in the enum `Key` within `firefox-ios/Ecosia/L10N/String.swift`
- All user-facing strings MUST be localized
- Reference language is `en` (English)
- Always add the English reference in `firefox-ios/Ecosia/L10N/en.lproj/Ecosia.strings`
- DO NOT localize debug strings or developer-only content
- Managed via **Transifex**

## Never Add Ecosia Strings to Firefox Files

- **NEVER** add new `MZLocalizedString` entries to `firefox-ios/Shared/Strings.swift` for Ecosia-specific UI
- `Shared/Strings.swift` is Mozilla/Firefox's string catalog
- Before adding a new key, **always check** `firefox-ios/Ecosia/L10N/String.swift` first — the key may already exist
- For Firefox strings that already cover a concept, reuse them rather than duplicating

## Adding a New String

1. Add the key to the `Key` enum in `firefox-ios/Ecosia/L10N/String.swift`:

    ```swift
    case addMoreDetailAboutYourFeedback = "Add more detail about your feedback..."
    ```

2. Add the English translation in `firefox-ios/Ecosia/L10N/en.lproj/Ecosia.strings`:

    ```
    "Add more detail about your feedback..." = "Add more detail about your feedback...";
    ```

3. Reference in code:
    - UIKit: `String.localized(.addMoreDetailAboutYourFeedback)`
    - SwiftUI: `EcosiaText(.addMoreDetailAboutYourFeedback)`

## Advanced Usage

- Markdown in localized strings: use `EcosiaText` component (auto-parses markdown)
- Pluralization: `String.localizedPlural(.key, num: count)`
- After upstream merges, rebrand Mozilla strings: `python3 ecosify-strings.py firefox-ios`
