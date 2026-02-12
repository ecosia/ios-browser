# Ecosia Wallpaper Strategy - Implementation Options

## Current State Analysis

### What Exists Now

**Location**: `firefox-ios/Client/Frontend/Home/Homepage/HomepageViewController.swift:351-355`

```swift
func newState(state: HomepageState) {
    // Ecosia: Use Ecosia NTP background instead of Firefox wallpaper
    if let ecosiaWallpaperState = getEcosiaNTPWallpaperState() {
        wallpaperView.wallpaperState = ecosiaWallpaperState
    } else {
        wallpaperView.wallpaperState = state.wallpaperState
    }
}
```

**What this does:**
- Intercepts Firefox's wallpaper state
- Uses `getNTPBackgroundConfiguration()` which loads `UIImage(named: "ntpBackground")`
- Completely bypasses Firefox's wallpaper download system
- Shows bundled image immediately on first launch

### Firefox's Default Behavior

**No default background image**:
- `Wallpaper.baseWallpaper` has `id: "fxDefault"` with `type: .none`
- When no wallpaper is selected, `pictureView.image = nil` (no background)
- User must explicitly select a wallpaper to see one

**Location**: `firefox-ios/Client/Frontend/Home/Homepage/Wallpapers/v1/Models/Wallpaper.swift:56-63`

```swift
static var baseWallpaper: Wallpaper {
    return Wallpaper(
        id: Wallpaper.noAssetID,  // "fxDefault"
        textColor: nil,
        cardColor: nil,
        logoTextColor: nil
    )
}

var hasImage: Bool {
    type != .none  // Returns false for baseWallpaper
}
```

## The Problem with Pure Approaches

### Option A: Keep Only the "Hack" (Current State)

**Pros:**
- ✅ Background visible on first launch
- ✅ No network dependency
- ✅ Works immediately

**Cons:**
- ❌ Bypasses entire wallpaper system
- ❌ Users can't customize wallpapers
- ❌ Can't leverage Firefox's UI and infrastructure
- ❌ If you set `MOZ_WALLPAPER_ASSET_URL`, Firefox downloads wallpapers in background but **never uses them** (waste of bandwidth and resources)

### Option B: Pure Download System (Remove Hack)

**Pros:**
- ✅ Reuses Firefox infrastructure
- ✅ Users can customize
- ✅ No wasted resources

**Cons:**
- ❌ **No background on first launch** (fails requirement)
- ❌ Blank homepage until user downloads a wallpaper
- ❌ Poor first impression

## Recommended: Option C - Smart Hybrid Approach

**Goal**: Background on first launch + full customization system + no wasted resources

### How It Works

1. **First Launch**: Show bundled Ecosia default immediately
2. **Background**: Initialize Firefox wallpaper system with `MOZ_WALLPAPER_ASSET_URL` pointing to Ecosia-only wallpapers
3. **User Choice**: User can later select from downloaded Ecosia wallpapers
4. **Smart Fallback**: If no wallpaper selected, show bundled default

### Implementation

#### Step 1: Create Ecosia Default Wallpaper

**Add to**: `firefox-ios/Client/Frontend/Home/Homepage/Wallpapers/v1/Models/Wallpaper.swift`

```swift
extension Wallpaper {
    /// Ecosia: Bundled default wallpaper available immediately on first launch
    static var ecosiaDefault: Wallpaper {
        return Wallpaper(
            id: "ecosia-default",
            textColor: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
            cardColor: UIColor(red: 0.1, green: 0.3, blue: 0.18, alpha: 1.0),
            logoTextColor: UIColor(red: 0.91, green: 0.96, blue: 0.91, alpha: 1.0),
            bundledAssetName: "ntpBackground"  // NEW field
        )
    }
}
```

#### Step 2: Extend Wallpaper Model

**Add optional field for bundled assets**:

```swift
struct Wallpaper: Equatable {
    let id: String
    let textColor: UIColor?
    let cardColor: UIColor?
    let logoTextColor: UIColor?
    let bundledAssetName: String?  // NEW: Optional bundled asset name

    // Existing computed properties for downloaded images
    var portrait: UIImage? {
        // NEW: Check bundled first
        if let assetName = bundledAssetName,
           let bundledImage = UIImage(named: assetName) {
            return bundledImage
        }

        // EXISTING: Fallback to downloaded image
        return fetchResourceFor(imageType: .portrait)
    }

    var landscape: UIImage? {
        // NEW: Check bundled first
        if let assetName = bundledAssetName,
           let bundledImage = UIImage(named: assetName) {
            return bundledImage
        }

        // EXISTING: Fallback to downloaded image
        return fetchResourceFor(imageType: .landscape)
    }
}
```

#### Step 3: Set Ecosia Default on First Launch

**Modify**: `firefox-ios/Client/Frontend/Home/Homepage/Wallpapers/v1/Utilities/WallpaperStorageUtility.swift`

```swift
public func fetchCurrentWallpaper() -> Wallpaper {
    if let data = userDefaults.object(forKey: PrefsKeys.Wallpapers.CurrentWallpaper) as? Data {
        do {
            return try JSONDecoder().decode(Wallpaper.self, from: data)
        } catch {
            logger.log("WallpaperStorageUtility decoding error: \(error.localizedDescription)",
                       level: .warning,
                       category: .homepage)
        }
    }

    // NEW: Return Ecosia default instead of baseWallpaper for first launch
    #if ECOSIA
    return Wallpaper.ecosiaDefault
    #else
    return Wallpaper.baseWallpaper
    #endif
}
```

#### Step 4: Configure Ecosia Wallpaper Server

**Set in build config**: `MOZ_WALLPAPER_ASSET_URL=https://wallpapers.ecosia.org`

**Host only Ecosia wallpapers** (not Firefox wallpapers), so downloads are:
- Ecosia-branded only
- Actually useful (user might select them)
- Not wasteful

#### Step 5: Remove Old Hack (Optional after testing)

Once the hybrid approach is working, you can remove:

```swift
// OLD: Remove this intercept
if let ecosiaWallpaperState = getEcosiaNTPWallpaperState() {
    wallpaperView.wallpaperState = ecosiaWallpaperState
} else {
    wallpaperView.wallpaperState = state.wallpaperState
}

// NEW: Just use the standard flow
wallpaperView.wallpaperState = state.wallpaperState
```

The system now handles Ecosia's default automatically via `fetchCurrentWallpaper()`.

## Comparison Table

| Aspect | Option A (Hack Only) | Option B (Pure Download) | **Option C (Hybrid)** ✅ |
|--------|---------------------|-------------------------|--------------------------|
| **First launch background** | ✅ Yes | ❌ No | ✅ Yes |
| **User customization** | ❌ No | ✅ Yes | ✅ Yes |
| **Wasted downloads** | ⚠️ Yes (if URL set) | ✅ No | ✅ No |
| **Reuses Firefox UI** | ❌ No | ✅ Yes | ✅ Yes |
| **Network dependency** | ✅ None | ❌ Required | ⚠️ Optional |
| **Code changes** | ✅ None | ⚠️ Config only | ⚠️ Small (5-10 lines) |
| **Offline experience** | ✅ Perfect | ❌ Poor | ✅ Perfect |
| **Future-proof** | ❌ No | ✅ Yes | ✅ Yes |

## Why Hybrid is Best

### User Experience
1. **First launch**: Beautiful Ecosia background immediately (no blank screen)
2. **Discovery**: User finds wallpaper settings, sees Ecosia collection
3. **Customization**: User can pick different Ecosia wallpapers
4. **Offline**: Always works (bundled default available)

### Technical Benefits
1. **No wasted bandwidth**: Only Ecosia wallpapers download (not unused Firefox ones)
2. **Reuses infrastructure**: Leverages tested Firefox code
3. **Minimal code changes**: ~10 lines of code
4. **Maintainable**: Works with future Firefox updates
5. **Flexible**: Can add more Ecosia wallpapers without app updates

### Resource Efficiency
- **No waste**: If user never changes wallpaper, only bundled asset is used (0 downloads)
- **Smart loading**: Downloads only happen if user browses wallpaper settings
- **Clean separation**: Ecosia wallpapers only, no mixed Firefox/Ecosia downloads

## Implementation Effort

**Option C (Hybrid)**:
- **Code changes**: 5-10 lines in 2 files
- **Assets**: Keep existing `ntpBackground` bundle
- **Infrastructure**: Same CDN setup as Option B
- **Testing**: 2-3 days
- **Total**: ~3 days engineering + CDN setup

## Migration Path

### Phase 1: Keep Current Hack (Ship Immediately)
- Current code works
- Background visible on first launch
- Buy time to implement hybrid

### Phase 2: Add Bundled Default Support
- Add `bundledAssetName` field to Wallpaper
- Update image loading logic
- Modify `fetchCurrentWallpaper()`

### Phase 3: Deploy Ecosia Wallpaper Server
- Host Ecosia wallpapers at CDN
- Set `MOZ_WALLPAPER_ASSET_URL`

### Phase 4: Remove Old Hack
- Remove intercept in `newState()`
- System uses standard flow

### Phase 5: Monitor & Iterate
- Track wallpaper engagement
- Add more Ecosia wallpapers based on usage

## Recommendation

**Ship with Phase 1 now** (keep the hack), then **implement Phases 2-4** in next release.

This gives you:
- ✅ Background on first launch (immediate ship)
- ✅ No wasted resources (proper implementation)
- ✅ Full customization (user value)
- ✅ Low risk (phased approach)

## Questions to Answer

1. **Should we ship the hack first, then improve?** (Recommended: Yes)
2. **How many Ecosia wallpapers for initial launch?** (Recommended: 3-5)
3. **Should bundled default be in wallpaper selector?** (Recommended: Yes, as "Ecosia Classic")
4. **Track which approach users prefer?** (Recommended: Yes, via telemetry)

## Technical Notes

### Why the Hack is "Wasteful"

If you keep the current hack AND set `MOZ_WALLPAPER_ASSET_URL`:

1. Firefox's `WallpaperManager.checkForUpdates()` runs on launch
2. Downloads metadata JSON from server
3. Downloads thumbnail images for wallpaper selector
4. Downloads full wallpapers if user browses settings
5. **BUT**: Your hack at line 351 means downloaded wallpapers are never used
6. **Result**: Bandwidth wasted, storage used, CPU cycles spent for nothing

### Why Hybrid Doesn't Waste

With the hybrid approach:

1. `fetchCurrentWallpaper()` returns bundled default on first launch
2. `WallpaperManager.checkForUpdates()` still runs (good!)
3. Downloads metadata and thumbnails (needed for UI)
4. Downloads full wallpapers **only if user selects them**
5. If user never changes wallpaper, only metadata downloaded (~5KB)
6. **Result**: Efficient, scales with user behavior

## Related Documentation

- [Implementation Plan](./ecosia-wallpaper-system-implementation-plan.md) - Full technical plan
- [Product Pitch](./ecosia-wallpaper-product-pitch.md) - Business case
- [Wallpaper Analysis](./wallpaper-configuration-analysis.md) - Deep dive into architecture
