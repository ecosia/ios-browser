# Wallpaper Onboarding System

## Overview

The wallpaper onboarding system was a **bottom sheet modal** that appeared once for new users to help them discover the wallpaper customization feature. This system **was removed from Firefox's new homepage in December 2024** (commit be28ead265) but the underlying infrastructure remains in the codebase.

## Current Status

⚠️ **Removed from Firefox**: The onboarding has been removed from Firefox's homepage rebuild
✅ **Infrastructure Still Present**: All APIs and UI components remain functional
❓ **Ecosia Decision Needed**: Should Ecosia implement this for their users?

## How It Worked

### Trigger Conditions

The onboarding appeared automatically when **all** of the following conditions were met:

1. **Zero Search State**: User was on the homepage (not in search mode)
2. **Modal Availability**: No other modal was currently being presented
3. **CFR Prerequisites**: Two Context Feature Recommendation (CFR) hints had been shown:
   - Toolbar Update CFR
   - Jump Back In CFR
4. **Sufficient Content**: At least the minimum number of wallpaper thumbnails were available (defined by `WallpaperThumbnailUtility.defaultMinimumNumberOfThumbnails`)
5. **First Time Only**: The onboarding had never been shown before (tracked by `PrefsKeys.Wallpapers.OnboardingSeenKey`)

### User Experience

1. **Presentation**: Bottom sheet slides up from bottom of screen
2. **Content**: Shows wallpaper selector with:
   - Header: "Tap to select wallpaper" (`.Onboarding.Wallpaper.SelectorTitle`)
   - Description: Instructions for selecting wallpaper (`.Onboarding.Wallpaper.SelectorDescription`)
   - Grid: Thumbnail grid of available wallpapers
3. **Interaction**: User can:
   - Select a wallpaper (downloads if needed, then applies it)
   - Dismiss the sheet (by tapping outside, if allowed)
4. **Completion**: After showing, `onboardingSeen()` is called to prevent future displays

### UI Components

**WallpaperSelectorViewController**
- Location: `Client/Frontend/Home/Homepage/Wallpapers/v1/UI/WallpaperSelectorViewController.swift`
- Purpose: Displays wallpaper selection grid
- Type: `BottomSheetChild` protocol conformant
- Layout: Responsive grid (3-4 items per row depending on device)

**BottomSheetViewController**
- Standard Firefox component for modal bottom sheets
- Configuration: `shouldDismissForTapOutside = false` (user must actively select or close)
- Accessibility: Close button with proper labels

### APIs

**WallpaperManagerInterface**
```swift
func canOnboardingBeShown(using: Profile) -> Bool
func onboardingSeen()
```

**WallpaperManager Implementation**
```swift
func canOnboardingBeShown(using profile: Profile) -> Bool {
    let cfrHintUtility = ContextualHintEligibilityUtility(with: profile, overlayState: nil)
    let toolbarUpdateCFRShown = !cfrHintUtility.canPresent(.toolbarUpdate)
    let jumpBackInCFRShown = !cfrHintUtility.canPresent(.jumpBackIn)
    let cfrsHaveBeenShown = toolbarUpdateCFRShown && jumpBackInCFRShown

    guard cfrsHaveBeenShown,
          hasEnoughThumbnailsToShow,
          !userDefaults.bool(forKey: PrefsKeys.Wallpapers.OnboardingSeenKey)
    else { return false }

    return true
}

func onboardingSeen() {
    userDefaults.set(true, forKey: PrefsKeys.Wallpapers.OnboardingSeenKey)
}
```

## Original Implementation

The onboarding was triggered from `HomepageCoordinator` (now deleted):

```swift
func showWallpaperSelectionOnboarding(_ canPresentModally: Bool) {
    guard canPresentModally,
          isZeroSearch,
          !router.isPresenting,
          wallpaperManager.canOnboardingBeShown(using: profile)
    else { return }

    let viewModel = WallpaperSelectorViewModel(wallpaperManager: wallpaperManager)
    let viewController = WallpaperSelectorViewController(viewModel: viewModel, windowUUID: windowUUID)
    var bottomSheetViewModel = BottomSheetViewModel(
        closeButtonA11yLabel: .CloseButtonTitle,
        closeButtonA11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.OtherButtons.closeButton
    )
    bottomSheetViewModel.shouldDismissForTapOutside = false
    let bottomSheetVC = BottomSheetViewController(
        viewModel: bottomSheetViewModel,
        childViewController: viewController,
        windowUUID: windowUUID
    )

    router.present(bottomSheetVC, animated: false, completion: nil)
    wallpaperManager.onboardingSeen()
}
```

## Debug Tools

A debug setting exists to reset the onboarding state:

**ResetWallpaperOnboardingPage**
- Location: `Client/Frontend/Settings/Main/Debug/ResetWallpaperOnboardingPage.swift`
- Purpose: Resets `OnboardingSeenKey` to `false` for testing
- Shows current state: "seen" or "unseen"

## Telemetry

The onboarding tracks user interactions:

- `GleanMetrics.Onboarding.wallpaperSelected`: Wallpaper selected during onboarding
- `GleanMetrics.Onboarding.wallpaperSelectorSelected`: Alternative event tracking

Telemetry includes:
- `wallpaperName`: ID of selected wallpaper
- `wallpaperType`: Type of wallpaper (default/classic/limitedEdition)

## Considerations for Ecosia

### Should Ecosia Implement This?

**Reasons to implement:**
- ✅ Helps users discover wallpaper customization feature
- ✅ Increases engagement with personalization
- ✅ Infrastructure already exists and is functional
- ✅ Can showcase Ecosia's nature-themed wallpapers

**Reasons to skip:**
- ❌ Firefox removed it for a reason (possibly low engagement?)
- ❌ Adds complexity to first-run experience
- ❌ May interrupt user flow
- ❌ Ecosia has different onboarding priorities

### Implementation Options

If Ecosia decides to implement onboarding:

1. **Recreate HomepageCoordinator approach**: Follow Firefox's original pattern
2. **Integrate into Ecosia onboarding flow**: Add as step in existing `Welcome.swift` flow
3. **Simpler approach**: Show settings icon hint/tooltip instead of full selector
4. **Delayed discovery**: Show on 2nd or 3rd app launch instead of first

### Required Changes

To implement for Ecosia:

1. **Create coordinator or delegate**:
   - Either recreate `HomepageCoordinator.swift`
   - Or add method to `EcosiaHomepageAdapter`

2. **Hook into homepage lifecycle**:
   - Call `canOnboardingBeShown()` at appropriate time
   - Present bottom sheet when conditions are met

3. **Customize for Ecosia**:
   - Update string resources (SelectorTitle, SelectorDescription)
   - Possibly adjust CFR prerequisites
   - Consider Ecosia-specific trigger conditions

4. **Testing**:
   - Use `ResetWallpaperOnboardingPage` debug setting
   - Verify CFR conditions
   - Test on different device sizes

## Files Reference

### Core Implementation
- `Client/Frontend/Home/Homepage/Wallpapers/v1/UI/WallpaperSelectorViewController.swift`
- `Client/Frontend/Home/Homepage/Wallpapers/v1/UI/WallpaperSelectorViewModel.swift`
- `Client/Frontend/Home/Homepage/Wallpapers/v1/Interface/WallpaperManager.swift`

### Debug Tools
- `Client/Frontend/Settings/Main/Debug/ResetWallpaperOnboardingPage.swift`

### Telemetry
- `Client/Telemetry/TelemetryWrapper.swift` (search for `Onboarding.wallpaper`)

### String Resources
- `.Onboarding.Wallpaper.SelectorTitle`
- `.Onboarding.Wallpaper.SelectorDescription`
- `.Onboarding.Wallpaper.ClassicWallpaper`
- `.Onboarding.Wallpaper.LimitedEditionWallpaper`

### Accessibility Identifiers
- `AccessibilityIdentifiers.Onboarding.Wallpaper.title`
- `AccessibilityIdentifiers.Onboarding.Wallpaper.description`
- `AccessibilityIdentifiers.Onboarding.Wallpaper.card`

## History

- **v109-v112**: Onboarding active with "Explore more" button
- **v112**: "Explore more" removed
- **v123**: `.wallpaperOnboardingSheet` feature flag removed
- **December 2024**: Onboarding completely removed from new homepage (commit be28ead265)
- **Current**: Infrastructure remains but not actively used

## Related Issues

- FXIOS-10862: Remove wallpaper selection onboarding from new homepage
- FXIOS-6745: Remove .wallpaperOnboardingSheet feature flag
- FXIOS-5788: Remove Explore more from wallpaper onboarding
