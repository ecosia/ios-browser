# Ecosia Symbol-Dependency Triage Report

Static heuristic scan of 132 Ecosia-owned files against the Firefox-core symbol table
at `firefox-v147.1` (baseline) vs `firefox-v155.1` (target). Flags any type or method name Ecosia references
that existed in core at the baseline but can no longer be found anywhere in the core tree at the target.

**This is a triage list, not a verdict.** Regex-based, no type-checker: false positives happen
(a common method name like `reload` renamed on one unrelated class elsewhere flags everywhere it's
called), and it can't catch a signature change that keeps the same name. Each flagged item still
needs a human/agent to open the file and the corresponding upstream diff and confirm.

**Result: 27 of 132 files have at least one flagged symbol, 32 flagged references total.**

---

## firefox-ios/Client/Ecosia/Bookmarks/BookmarksExchange.swift
- **Possibly-removed/renamed types referenced:** BookmarkItem, SimpleToast

## firefox-ios/Client/Ecosia/Extensions/AppSettingsTableViewController+Ecosia.swift
- **Possibly-removed/renamed methods called:** append, isFeatureEnabled

## firefox-ios/Client/Ecosia/Extensions/BrowserCoordinator+Ecosia.swift
- **Possibly-removed/renamed types referenced:** SimpleToast

## firefox-ios/Client/Ecosia/Extensions/BrowserViewController+Ecosia.swift
- **Possibly-removed/renamed types referenced:** Intro

## firefox-ios/Client/Ecosia/Extensions/BrowserViewController+EcosiaErrorHandling.swift
- **Possibly-removed/renamed methods called:** append

## firefox-ios/Client/Ecosia/Extensions/HomepageViewController+Ecosia.swift
- **Possibly-removed/renamed methods called:** animate

## firefox-ios/Client/Ecosia/Extensions/HomepageViewController+EcosiaSetup.swift
- **Possibly-removed/renamed methods called:** animate

## firefox-ios/Client/Ecosia/Extensions/SimpleToast+Ecosia.swift
- **Possibly-removed/renamed types referenced:** SimpleToast
- **Possibly-removed/renamed methods called:** animate

## firefox-ios/Client/Ecosia/Frontend/Home/EcosiaHomepageAdapter.swift
- **Possibly-removed/renamed types referenced:** Customization
- **Possibly-removed/renamed methods called:** append

## firefox-ios/Client/Ecosia/Frontend/Home/EcosiaHomepageSectionType.swift
- **Possibly-removed/renamed methods called:** append

## firefox-ios/Client/Ecosia/Settings/EcosiaDebugSettings.swift
- **Possibly-removed/renamed types referenced:** Provider

## firefox-ios/Client/Ecosia/Settings/EcosiaSettings.swift
- **Possibly-removed/renamed types referenced:** SimpleToast

## firefox-ios/Client/Ecosia/UI/BeforeOrAfterView.swift
- **Possibly-removed/renamed methods called:** append

## firefox-ios/Client/Ecosia/UI/EmptyBookmarksView.swift
- **Possibly-removed/renamed methods called:** append

## firefox-ios/Client/Ecosia/UI/MultiplyImpact/MultiplyImpact.swift
- **Possibly-removed/renamed methods called:** share

## firefox-ios/Client/Ecosia/UI/NTP/Impact/NTPImpactCell.swift
- **Possibly-removed/renamed methods called:** append

## firefox-ios/Client/Ecosia/UI/NTP/Impact/NTPImpactCellViewModel.swift
- **Possibly-removed/renamed methods called:** append

## firefox-ios/Client/Ecosia/UI/NTP/Library/NTPLibraryCell.swift
- **Possibly-removed/renamed methods called:** append

## firefox-ios/Client/Ecosia/UI/NTP/News/NTPNewsCell.swift
- **Possibly-removed/renamed methods called:** animate

## firefox-ios/Client/Ecosia/UI/NTP/SearchBar/NTPSearchBarBackdropView.swift
- **Possibly-removed/renamed methods called:** animate

## firefox-ios/Client/Ecosia/UI/NTP/SearchBar/NTPSearchBarView.swift
- **Possibly-removed/renamed methods called:** append, setTextWithoutSearching

## firefox-ios/Client/Ecosia/UI/NTP/SearchBar/Upload/NTPOmniboxSheetState.swift
- **Possibly-removed/renamed types referenced:** Provider

## firefox-ios/Client/Ecosia/UI/NTP/SearchBar/Upload/OmniboxUploadFileSelectionValidator.swift
- **Possibly-removed/renamed methods called:** append

## firefox-ios/Client/Ecosia/UI/NTP/SearchBar/Upload/OmniboxUploadPhotoPicker.swift
- **Possibly-removed/renamed methods called:** append

## firefox-ios/Client/Ecosia/UI/PageAction/PageActionsShortcutsHeader.swift
- **Possibly-removed/renamed methods called:** append

## firefox-ios/Client/Ecosia/UI/ProductTour/BrowserViewController+WelcomeTransition.swift
- **Possibly-removed/renamed methods called:** animate

## firefox-ios/Client/Ecosia/UI/WhatsNew/DataProvider/WhatsNewLocalDataProvider.swift
- **Possibly-removed/renamed methods called:** append
