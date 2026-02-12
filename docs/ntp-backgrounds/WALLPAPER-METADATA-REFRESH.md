# Wallpaper Metadata Refresh Logic

## When Metadata is Fetched

The wallpaper metadata JSON (`wallpapers.json`) is automatically fetched from the server in these scenarios:

### 1. **App Launch** (Primary Trigger)

Every time the app launches, `AppDelegate.updateWallpaperMetadata()` calls `WallpaperManager.checkForUpdates()`.

**Code location:** `firefox-ios/Client/Application/AppDelegate.swift:332`

```swift
private func updateWallpaperMetadata() {
    wallpaperMetadataQueue.async {
        let wallpaperManager = WallpaperManager()
        wallpaperManager.checkForUpdates()
    }
}
```

### 2. **Rate Limiting: Once Per Day Maximum**

The system checks if metadata should be refreshed using this logic:

**Code location:** `WallpaperMetadataUtility.swift:16-23`

```swift
private var shouldCheckForNewMetadata: Bool {
    guard let existingDate = userDefaults.object(forKey: prefsKey) as? Date else {
        return true  // Never checked before
    }
    let todaysDate = Calendar.current.startOfDay(for: Date())

    if existingDate == todaysDate {
        return false  // Already checked today
    }

    return true  // New day, check again
}
```

**Key:** `PrefsKeys.Wallpapers.MetadataLastCheckedDate`

**Rules:**
- ✅ **First launch** → Fetches metadata
- ✅ **New day** → Fetches metadata
- ❌ **Same day** → Skips fetch (returns cached metadata)

### 3. **What Gets Updated**

When metadata is fetched:

1. **Compares** new metadata with stored metadata
2. **If different** → Stores new metadata, downloads missing thumbnails, runs migration
3. **If identical** → Updates last-checked date only (no re-download)
4. **Thumbnails** → Always attempts to download missing thumbnails (even if metadata unchanged)

**Code location:** `WallpaperManager.checkForUpdates()` (lines 200-223)

## How to Force a Metadata Refresh

### Option 1: Delete App Data (Recommended for Users)

**Steps:**
1. Long-press the Ecosia app icon
2. Select "Remove App" → "Delete App"
3. Reinstall from App Store or TestFlight
4. First launch will fetch fresh metadata

**Effect:** Complete reset, all wallpaper data cleared

### Option 2: Reset Metadata Date (Developer/QA)

**Using Xcode:**

1. Run app in Xcode with breakpoint
2. In LLDB console:
   ```lldb
   po UserDefaults.standard.removeObject(forKey: "Wallpapers.MetadataLastCheckedDate")
   ```
3. Continue execution
4. Kill and relaunch app → metadata will be fetched

**Using code (temporary debug option):**

Add to `AppDelegate.application(_:didFinishLaunchingWithOptions:)`:

```swift
#if DEBUG
// Force metadata refresh (remove for production)
UserDefaults.standard.removeObject(forKey: "Wallpapers.MetadataLastCheckedDate")
#endif
```

**Effect:** Next app launch will fetch metadata

### Option 3: Change System Date (Testing)

**Steps:**
1. Open Settings → General → Date & Time
2. Toggle off "Set Automatically"
3. Change date to tomorrow
4. Relaunch app → metadata will be fetched
5. **Important:** Reset date afterwards!

**Effect:** Bypasses once-per-day check

### Option 4: Delete Metadata File (Developer)

**Using Simulator:**

```bash
# Find metadata file
find ~/Library/Developer/CoreSimulator/Devices -name "metadata" -path "*/wallpapers/*" 2>/dev/null

# Delete it
rm /path/to/metadata/file

# Relaunch app
```

**Effect:** App treats it as first launch, fetches metadata

## Metadata Storage Locations

### UserDefaults Keys

| Key | Type | Purpose |
|-----|------|---------|
| `Wallpapers.MetadataLastCheckedDate` | Date | Tracks last metadata check (rate limiting) |
| `Wallpapers.CurrentWallpaper` | Data | Encoded currently-selected wallpaper |
| `Wallpapers.ThumbnailsAvailable` | Bool | Whether enough thumbnails exist to show UI |
| `Wallpapers.OnboardingSeenKey` | Bool | Whether wallpaper onboarding was shown |

### File System

```
~/Library/Application Support/
└── wallpapers/
    ├── metadata/
    │   └── metadata              # JSON metadata file
    ├── thumbnails/
    │   ├── ecosia-default_thumbnail.png
    │   ├── ecosia-forest_thumbnail.png
    │   └── ...
    ├── ecosia-default/
    │   ├── ecosia-default_iPhone_portrait.png
    │   └── ecosia-default_iPhone_landscape.png
    └── ecosia-forest/
        ├── ecosia-forest_iPhone_portrait.png
        └── ecosia-forest_iPhone_landscape.png
```

## Debug Logging

The codebase includes comprehensive debug logging with `🐛WALLPAPER_DEBUG` prefix:

**View in Xcode Console:**

1. Run app in Xcode
2. Filter console: Search for `WALLPAPER_DEBUG`
3. Look for:
   ```
   🐛WALLPAPER_DEBUG WallpaperManager.checkForUpdates() - START
   🐛WALLPAPER_DEBUG WallpaperMetadataUtility.metadataUpdateFetchedNewData() - ...
   ```

**Key log messages:**

- `shouldCheckForNewMetadata: true/false` → Whether fetch will happen
- `Already checked today` → Rate limit hit
- `Fetched X collections` → Successful fetch
- `New metadata differs from old` → Update needed
- `Metadata unchanged` → No update needed

## Testing Metadata Changes

### Local Testing Workflow

1. **Update JSON:**
   ```bash
   vim docs/metadata/v1/wallpapers.json
   # Add/modify wallpaper or collection
   ```

2. **Validate:**
   ```bash
   cd docs/metadata/v1
   npm run validate
   ```

3. **Commit & Push:**
   ```bash
   git add docs/metadata/v1/wallpapers.json
   git commit -m "Add new wallpaper collection"
   git push
   ```

4. **Force App Refresh:**
   ```swift
   // In AppDelegate or debug code
   UserDefaults.standard.removeObject(forKey: "Wallpapers.MetadataLastCheckedDate")
   ```

5. **Relaunch App** → New metadata will be fetched

### Expected Behavior

After forcing refresh with updated metadata:

1. **Console shows:**
   ```
   🐛WALLPAPER_DEBUG Fetched metadata from server
   🐛WALLPAPER_DEBUG New metadata differs from old, storing...
   🐛WALLPAPER_DEBUG Fetching thumbnails for X collections...
   ```

2. **Settings → Homepage:**
   - New collections appear
   - New wallpapers appear in existing collections
   - Thumbnails download in background

3. **UserDefaults updated:**
   - `MetadataLastCheckedDate` → Current date
   - `ThumbnailsAvailable` → `true` (after thumbnails download)

## Production Considerations

### CDN Caching

If using a CDN (e.g., CloudFront, Fastly):

- **Cache-Control:** Set short TTL for `wallpapers.json` (e.g., 5 minutes)
- **Invalidation:** Manually invalidate CDN cache after updating JSON
- **Versioning:** Consider adding version parameter: `wallpapers.json?v=2026-02-12`

### Deployment Checklist

Before deploying metadata changes:

1. ✅ Validate JSON schema
2. ✅ Upload all referenced images to CDN
3. ✅ Test download URLs work
4. ✅ Check date ranges (availability-range)
5. ✅ Verify locale restrictions
6. ✅ Test on physical device (not just simulator)
7. ✅ Monitor app logs for errors

### Rollback Plan

If bad metadata is deployed:

1. **Revert JSON** on server/CDN
2. **Invalidate CDN cache** (if applicable)
3. **Wait 24 hours** → All active users will refetch
4. **Or push app update** that forces metadata refresh

## Frequency vs Performance

### Current: Once Per Day

**Pros:**
- Reasonable balance
- New wallpapers appear within 24 hours
- Minimal battery/bandwidth impact

**Cons:**
- Urgent updates take up to 24 hours
- Can't push immediate fixes

### Alternative Strategies

**More Frequent (e.g., Every 6 Hours):**
```swift
private var shouldCheckForNewMetadata: Bool {
    guard let existingDate = userDefaults.object(forKey: prefsKey) as? Date else { return true }
    let now = Date()
    let hoursSinceLastCheck = Calendar.current.dateComponents([.hour], from: existingDate, to: now).hour ?? 0
    return hoursSinceLastCheck >= 6  // Check every 6 hours
}
```

**On-Demand (User Pull-to-Refresh):**
- Add pull-to-refresh gesture in wallpaper settings
- Bypasses rate limit when user explicitly refreshes
- Best UX for power users

**Push Notifications:**
- Send silent push when metadata changes
- App fetches immediately upon receiving push
- Requires backend infrastructure

## Troubleshooting

### Metadata Not Updating

**Check these in order:**

1. **Rate Limit Hit?**
   ```
   Log: "Already checked today"
   Solution: Wait until tomorrow or force refresh
   ```

2. **Network Error?**
   ```
   Log: "Failed to fetch new metadata: [error]"
   Solution: Check MOZ_WALLPAPER_ASSET_URL in Info.plist
   ```

3. **Metadata Identical?**
   ```
   Log: "Metadata unchanged, marking date only"
   Solution: Ensure JSON actually changed (check last-updated-date)
   ```

4. **URL Wrong?**
   ```
   Log: "No value found for key 'MOZ_WALLPAPER_ASSET_URL'"
   Solution: Check build configuration (EcosiaDebug.xcconfig)
   ```

### Thumbnails Not Downloading

1. **Check image URLs** → Must be `https://` and publicly accessible
2. **Check filename format** → Must be `{id}_thumbnail.jpg`
3. **Check verification logic** → Needs at least 4 thumbnails to enable UI
4. **Check disk space** → iOS may prevent downloads if storage full

## Related Documentation

- **[Wallpaper Validation](./WALLPAPER-VALIDATION.md)** - JSON Schema and validation
- **[Firefox Wallpapers Wiki](https://github.com/mozilla-mobile/firefox-ios/wiki/Wallpapers)** - Original documentation
- **[Ecosia Wallpaper Strategy](./ecosia-wallpaper-strategy-options.md)** - Architecture decisions
