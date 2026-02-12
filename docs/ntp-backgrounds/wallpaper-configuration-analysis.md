# WallpaperConfiguration Analysis

## Executive Summary

**Key Finding**: Firefox and Ecosia have fundamentally different approaches to wallpapers:

- **Firefox**: Downloads wallpapers from web servers, stores 4 separate images per wallpaper (iPhone/iPad × portrait/landscape), and allows users to select from multiple wallpapers
- **Ecosia**: Uses a single bundled image (`ntpBackground`) for all orientations and devices

Both implementations use the same `WallpaperConfiguration` structure with `landscapeImage` and `portraitImage` properties, but:
- Firefox populates these with **different images** optimized for each orientation
- Ecosia sets both to the **same image**, making the orientation switching transparent but not optimized

## Overview

This document analyzes how `WallpaperConfiguration` works in the codebase, specifically focusing on the `landscapeImage` and `portraitImage` properties and how they're used differently between Firefox and Ecosia implementations.

## WallpaperConfiguration Structure

**Location**: `firefox-ios/Client/Frontend/Home/Homepage/Wallpapers/Redux/WallpaperState.swift:45-83`

```swift
struct WallpaperConfiguration: Equatable {
    var id: String?
    var landscapeImage: UIImage?
    var portraitImage: UIImage?
    var textColor: UIColor?
    var cardColor: UIColor?
    var logoTextColor: UIColor?
    var hasImage: Bool
}
```

The configuration has two initializers:
1. Manual initialization with all parameters
2. Initialization from a `Wallpaper` object that extracts `wallpaper.landscape` and `wallpaper.portrait`

## Where Images Come From

### Firefox Original Implementation: Web-Downloaded Assets

Firefox wallpapers are **downloaded from the web** and cached locally. Here's the complete flow:

#### 1. Source & URL Configuration

**Location**: `firefox-ios/Client/Info.plist:96-97`

The base URL comes from an environment variable:
```xml
<key>MozWallpaperURLScheme</key>
<string>$(MOZ_WALLPAPER_ASSET_URL)</string>
```

**Location**: `firefox-ios/Client/Frontend/Home/Homepage/Wallpapers/v1/Utilities/WallpaperURLProvider.swift`

URLs are constructed as:
- Metadata: `{baseURL}/metadata/v1/wallpapers.json`
- Images: `{baseURL}/ios/{wallpaperId}/{wallpaperId}_{device}_{orientation}.jpg`

#### 2. Download Process

**Location**: `firefox-ios/Client/Frontend/Home/Homepage/Wallpapers/v1/Interface/WallpaperManager.swift:133-164`

When a user selects a wallpaper, the manager downloads both images simultaneously:

```swift
func fetchAssetsFor(_ wallpaper: Wallpaper, completion: @escaping (Result<Void, Error>) -> Void) {
    // Download both images at the same time for efficiency
    async let portraitFetchRequest = dataService.getImage(
        named: wallpaper.portraitID,
        withFolderName: wallpaper.id)
    async let landscapeFetchRequest = dataService.getImage(
        named: wallpaper.landscapeID,
        withFolderName: wallpaper.id)

    let (portrait, landscape) = await (try portraitFetchRequest, try landscapeFetchRequest)

    try storageUtility.store(portrait, withName: wallpaper.portraitID, andKey: wallpaper.id)
    try storageUtility.store(landscape, withName: wallpaper.landscapeID, andKey: wallpaper.id)
}
```

#### 3. Storage Location

**Location**: `firefox-ios/Client/Frontend/Home/Homepage/Wallpapers/v1/Utilities/WallpaperFilePathProvider.swift:72-87`

Images are stored in the Application Support directory:
```
~/Library/Application Support/{AppBundle}/wallpapers/{wallpaperId}/{imageName}.png
```

Structure:
- `wallpapers/metadata/metadata` - Wallpaper collections metadata JSON
- `wallpapers/thumbnails/{id}_thumbnail` - Thumbnail images
- `wallpapers/{wallpaperId}/{wallpaperId}_iPhone_portrait` - iPhone portrait image
- `wallpapers/{wallpaperId}/{wallpaperId}_iPhone_landscape` - iPhone landscape image
- `wallpapers/{wallpaperId}/{wallpaperId}_iPad_portrait` - iPad portrait image
- `wallpapers/{wallpaperId}/{wallpaperId}_iPad_landscape` - iPad landscape image

#### 4. Retrieval & Usage

**Location**: `firefox-ios/Client/Frontend/Home/Homepage/Wallpapers/v1/Models/Wallpaper.swift:82-116`

The `Wallpaper` model provides computed properties that fetch from storage:
```swift
var portrait: UIImage? {
    return fetchResourceFor(imageType: .portrait)
}

var landscape: UIImage? {
    return fetchResourceFor(imageType: .landscape)
}

private func fetchResourceFor(imageType: ImageTypeID) -> UIImage? {
    let storageUtility = WallpaperStorageUtility()
    return try? storageUtility.fetchImageNamed(portraitID) // or landscapeID
}
```

#### 5. Cleanup

**Location**: `firefox-ios/Client/Frontend/Home/Homepage/Wallpapers/v1/Utilities/WallpaperStorageUtility.swift:116-173`

Unused wallpaper images are automatically cleaned up to save disk space, keeping only:
- The currently selected wallpaper's images
- All available thumbnails
- Metadata

**Key characteristics**:
- ✅ Downloaded from web servers
- ✅ Separate optimized images for each orientation and device type
- ✅ Cached locally for offline access
- ✅ Automatic cleanup of unused assets
- ✅ Dynamic - can be updated without app updates

### Ecosia's Implementation

**Location**: `firefox-ios/Client/Ecosia/Frontend/Home/EcosiaHomepageAdapter.swift:219-231`

```swift
func getNTPBackgroundConfiguration() -> WallpaperConfiguration {
    let backgroundImage = UIImage(named: "ntpBackground")

    return WallpaperConfiguration(
        id: "ecosia-ntp-background",
        landscapeImage: backgroundImage,  // Same image
        portraitImage: backgroundImage,   // Same image
        textColor: nil,
        cardColor: nil,
        logoTextColor: nil,
        hasImage: backgroundImage != nil
    )
}
```

**Usage**: Called from `HomepageViewController+EcosiaSetup.swift:149`:
```swift
let wallpaperConfig = adapter.getNTPBackgroundConfiguration()
return WallpaperState(windowUUID: windowUUID, wallpaperConfiguration: wallpaperConfig)
```

**Key characteristic**: Ecosia uses the **same image for both orientations** instead of separate landscape/portrait images.

## How Images Are Used

**Location**: `firefox-ios/Client/Frontend/Home/Homepage/Wallpapers/WallpaperBackgroundView.swift:61-66`

```swift
private func currentWallpaperImage(from wallpaperState: WallpaperState) -> UIImage? {
    let isLandscape = UIDevice.current.orientation.isLandscape
    return isLandscape ?
        wallpaperState.wallpaperConfiguration.landscapeImage :
        wallpaperState.wallpaperConfiguration.portraitImage
}
```

The view switches between the two images based on device orientation, with a 0.3s animation (line 55-58).

## Key Differences Between Firefox and Ecosia

| Aspect | Firefox | Ecosia |
|--------|---------|--------|
| **Image Source** | Downloaded from web (CDN/remote server) | Bundled asset (`ntpBackground`) in app |
| **Orientation Handling** | Separate images: portrait + landscape | Same image for both orientations |
| **Device Handling** | Separate images: iPhone + iPad versions | Single image for all devices |
| **Storage Location** | `Application Support/wallpapers/` directory | Asset catalog (app bundle) |
| **File Format** | PNG (converted from JPG downloads) | Asset catalog format |
| **Naming Convention** | `{id}_{device}_{orientation}` | `ntpBackground` |
| **Image Count per Wallpaper** | 4 images (iPhone/iPad × portrait/landscape) | 1 image (reused for all) |
| **Dynamic Updates** | Can update without app release | Requires app update |
| **Disk Space** | Variable (downloads on demand, cleanup) | Fixed (bundled in app) |
| **Offline Availability** | After first download | Always available |
| **User Selection** | Multiple wallpapers to choose from | Single static background |
| **Metadata** | JSON from server with collections | Hardcoded in `getNTPBackgroundConfiguration()` |

## Potential Improvements

Since Ecosia uses the same image for both orientations, there's an opportunity to optimize by:

1. **Creating separate landscape and portrait images** that are better composed for each orientation
2. **Ensuring proper aspect ratios** so images don't need aggressive cropping in either orientation
3. **Using gradient overlays differently** for each orientation if needed for text readability

## Firefox Architecture: Complete Flow

Here's how Firefox's wallpaper system works end-to-end:

1. **App Launch** → `WallpaperManager.checkForUpdates()` checks for new wallpapers
2. **Metadata Download** → `WallpaperDataService.getMetadata()` fetches wallpaper collections JSON
3. **Metadata Storage** → `WallpaperStorageUtility.store(metadata)` saves to disk
4. **Thumbnail Download** → Thumbnails downloaded for wallpaper selector UI
5. **User Selection** → User picks wallpaper in settings
6. **Asset Download** → `WallpaperManager.fetchAssetsFor()` downloads portrait + landscape images
7. **Asset Storage** → Images saved as PNG to `Application Support/wallpapers/{id}/`
8. **Current Wallpaper** → Selected wallpaper saved to UserDefaults
9. **Display** → `WallpaperBackgroundView` loads from storage and displays based on orientation
10. **Cleanup** → `WallpaperStorageUtility.cleanupUnusedAssets()` removes old wallpapers

## Related Files

### Redux State Management
- `firefox-ios/Client/Frontend/Home/Homepage/Wallpapers/Redux/WallpaperState.swift` - State definition
- `firefox-ios/Client/Frontend/Home/Homepage/Wallpapers/Redux/WallpaperMiddleware.swift` - Middleware for state updates
- `firefox-ios/Client/Frontend/Home/Homepage/Wallpapers/Redux/WallpaperAction.swift` - Redux actions

### Models
- `firefox-ios/Client/Frontend/Home/Homepage/Wallpapers/v1/Models/Wallpaper.swift` - Wallpaper model with computed image properties
- `firefox-ios/Client/Frontend/Home/Homepage/Wallpapers/v1/Models/WallpaperCollection.swift` - Collection grouping
- `firefox-ios/Client/Frontend/Home/Homepage/Wallpapers/v1/Models/WallpaperMetadata.swift` - Server metadata structure

### Core Management
- `firefox-ios/Client/Frontend/Home/Homepage/Wallpapers/v1/Interface/WallpaperManager.swift` - Main wallpaper manager interface

### Networking
- `firefox-ios/Client/Frontend/Home/Homepage/Wallpapers/v1/NetworkServices/WallpaperDataService.swift` - Data fetching coordinator
- `firefox-ios/Client/Frontend/Home/Homepage/Wallpapers/v1/NetworkServices/WallpaperImageLoader.swift` - Image download
- `firefox-ios/Client/Frontend/Home/Homepage/Wallpapers/v1/NetworkServices/WallpaperMetadataLoader.swift` - Metadata download
- `firefox-ios/Client/Frontend/Home/Homepage/Wallpapers/v1/NetworkServices/WallpaperNetworkModule.swift` - Network layer abstraction

### Storage & File Management
- `firefox-ios/Client/Frontend/Home/Homepage/Wallpapers/v1/Utilities/WallpaperStorageUtility.swift` - File storage operations
- `firefox-ios/Client/Frontend/Home/Homepage/Wallpapers/v1/Utilities/WallpaperFilePathProvider.swift` - Path generation
- `firefox-ios/Client/Frontend/Home/Homepage/Wallpapers/v1/Utilities/WallpaperURLProvider.swift` - URL construction for downloads
- `firefox-ios/Client/Frontend/Home/Homepage/Wallpapers/v1/Utilities/WallpaperMetadataUtility.swift` - Metadata management
- `firefox-ios/Client/Frontend/Home/Homepage/Wallpapers/v1/Utilities/WallpaperThumbnailUtility.swift` - Thumbnail handling
- `firefox-ios/Client/Frontend/Home/Homepage/Wallpapers/v1/Utilities/WallpaperMigrationUtility.swift` - Version migration

### UI
- `firefox-ios/Client/Frontend/Home/Homepage/Wallpapers/WallpaperBackgroundView.swift` - View that displays wallpapers
- `firefox-ios/Client/Frontend/Settings/HomepageSettings/WallpaperSettings/v1/WallpaperSettingsViewController.swift` - Settings UI
- `firefox-ios/Client/Frontend/Settings/HomepageSettings/WallpaperSettings/v1/WallpaperSettingsViewModel.swift` - Settings view model
- `firefox-ios/Client/Frontend/Home/Homepage/Wallpapers/v1/UI/WallpaperSelectorViewController.swift` - Wallpaper picker UI

### Ecosia Implementation
- `firefox-ios/Client/Ecosia/Frontend/Home/EcosiaHomepageAdapter.swift` - Ecosia's configuration provider
- `firefox-ios/Client/Ecosia/Extensions/HomepageViewController+EcosiaSetup.swift` - Ecosia's usage

### Configuration
- `firefox-ios/Client/Info.plist` - Contains `MozWallpaperURLScheme` key with base URL

## Testing

Tests verify both landscape and portrait images are set correctly:
- `firefox-ios/firefox-ios-tests/Tests/ClientTests/Frontend/Homepage/Wallpaper/WallpaperStateTests.swift`
