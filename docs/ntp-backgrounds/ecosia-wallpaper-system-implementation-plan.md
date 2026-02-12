# Ecosia Wallpaper System - Implementation Plan

## Executive Summary

**Proposal**: Use Firefox's existing wallpaper infrastructure with Ecosia-hosted wallpaper assets.

**Current State**: Ecosia does not currently use Firefox's wallpaper system.

**Proposed State**: Leverage Firefox's complete wallpaper system with zero code changes:
- Host Ecosia wallpapers on a CDN/server
- Create metadata JSON with Ecosia wallpaper collections
- Point Firefox's system to Ecosia's wallpaper endpoint
- Users get orientation-specific images (portrait vs landscape)
- Users get device-specific images (iPhone vs iPad)
- Users can choose from multiple Ecosia wallpapers

**Effort**: Minimal - infrastructure, assets, and UI already exist.

## Why This is Simple

Firefox's wallpaper system is **complete and production-ready**. We don't need to modify any code - just:

1. ✅ **UI exists** - Wallpaper selector already built
2. ✅ **Download logic exists** - Handles portrait/landscape/iPhone/iPad
3. ✅ **Caching exists** - Stores wallpapers locally after download
4. ✅ **State management exists** - Redux integration ready
5. ✅ **Settings integration exists** - Already in Settings menu

**All we need**: Host wallpapers and create a metadata JSON file.

## Architecture Overview

### How Firefox's System Works

```
1. App reads metadata URL from Info.plist (MOZ_WALLPAPER_ASSET_URL)
2. Downloads metadata JSON from: {baseURL}/metadata/v1/wallpapers.json
3. Displays wallpapers in Settings → Homepage → Wallpapers
4. When user selects wallpaper, downloads 4 images:
   - {baseURL}/ios/{wallpaperId}/{wallpaperId}_iPhone_portrait.jpg
   - {baseURL}/ios/{wallpaperId}/{wallpaperId}_iPhone_landscape.jpg
   - {baseURL}/ios/{wallpaperId}/{wallpaperId}_iPad_portrait.jpg
   - {baseURL}/ios/{wallpaperId}/{wallpaperId}_iPad_landscape.jpg
5. Caches images locally in Application Support directory
6. Displays appropriate image based on device orientation
```

**For Ecosia**: We just need to host these files at our own URL.

## Implementation Plan

### Step 1: Host Wallpaper Assets

#### Where to Host
- **Option A**: Existing Ecosia CDN
- **Option B**: AWS S3 + CloudFront
- **Option C**: GitHub Pages (for testing/MVP)

#### File Structure Required

```
https://wallpapers.ecosia.org/
├── metadata/
│   └── v1/
│       └── wallpapers.json          (metadata file)
└── ios/
    ├── ecosia-forest/
    │   ├── ecosia-forest_iPhone_portrait.jpg
    │   ├── ecosia-forest_iPhone_landscape.jpg
    │   ├── ecosia-forest_iPad_portrait.jpg
    │   └── ecosia-forest_iPad_landscape.jpg
    ├── ecosia-ocean/
    │   ├── ecosia-ocean_iPhone_portrait.jpg
    │   ├── ecosia-ocean_iPhone_landscape.jpg
    │   ├── ecosia-ocean_iPad_portrait.jpg
    │   └── ecosia-ocean_iPad_landscape.jpg
    └── ecosia-mountains/
        └── (same structure)
```

### Step 2: Create Metadata JSON

**File**: `wallpapers.json`

**Location**: Must be hosted at `{BASE_URL}/metadata/v1/wallpapers.json`

```json
{
  "last-updated-date": "2026-02-11",
  "collections": [
    {
      "id": "ecosia-nature",
      "heading": "Ecosia Nature",
      "description": "Beautiful nature-inspired backgrounds",
      "learn-more-url": "https://ecosia.org/wallpapers",
      "available-locales": null,
      "availability-range": null,
      "wallpapers": [
        {
          "id": "ecosia-forest",
          "text-color": "FFFFFF",
          "card-color": "1A4D2E",
          "logo-text-color": "E8F5E9"
        },
        {
          "id": "ecosia-ocean",
          "text-color": "FFFFFF",
          "card-color": "1B4965",
          "logo-text-color": "CAE9FF"
        },
        {
          "id": "ecosia-mountains",
          "text-color": "FFFFFF",
          "card-color": "2C3E50",
          "logo-text-color": "ECF0F1"
        }
      ]
    }
  ]
}
```

**Field Descriptions**:
- `last-updated-date` - ISO 8601 date (YYYY-MM-DD) when metadata was last updated
- `id` - Wallpaper identifier (used in image URLs)
- `text-color` - Hex color for text overlay (without # symbol)
- `card-color` - Hex color for semi-transparent cards (without # symbol)
- `logo-text-color` - Hex color for Ecosia logo (without # symbol)
- `learn-more-url` - Optional URL for "Learn More" button
- `available-locales` - Optional array of locale codes (null = available everywhere)
- `availability-range` - Optional object with `start` and `end` dates (null = always available)

**Note**: Firefox's production wallpaper URL is not in the codebase (set via CI/CD). For Ecosia, you'll set `MOZ_WALLPAPER_ASSET_URL` in your build configuration.

### Step 3: Configure App to Point to Ecosia URL

**File**: `firefox-ios/Client/Info.plist`

Current (Firefox):
```xml
<key>MozWallpaperURLScheme</key>
<string>$(MOZ_WALLPAPER_ASSET_URL)</string>
```

**For Ecosia**: Set `MOZ_WALLPAPER_ASSET_URL` to `https://wallpapers.ecosia.org` in build configuration.

**That's it** - no code changes needed!

## Asset Requirements

### What Designers Need to Create

For **each wallpaper**, create 4 JPG images:

| Image | Device | Orientation | Size | Format |
|-------|--------|-------------|------|--------|
| `{id}_iPhone_portrait.jpg` | iPhone | Portrait | 1170 × 2532 px (@3x) | JPG, 85% quality |
| `{id}_iPhone_landscape.jpg` | iPhone | Landscape | 2532 × 1170 px (@3x) | JPG, 85% quality |
| `{id}_iPad_portrait.jpg` | iPad | Portrait | 2048 × 2732 px (@2x) | JPG, 85% quality |
| `{id}_iPad_landscape.jpg` | iPad | Landscape | 2732 × 2048 px (@2x) | JPG, 85% quality |

**Plus**: Define 3 hex colors per wallpaper:
- Text color (for readable overlays)
- Card color (for semi-transparent backgrounds)
- Logo color (for Ecosia logo)

**File size target**: ~500KB - 1MB per image (compressed JPG)

### Design Guidelines

1. **Composition**: Each orientation should be composed for that aspect ratio, not just cropped
2. **Safe areas**: Keep important content away from edges (avoid UI overlap)
3. **Readability**: Ensure chosen text colors provide sufficient contrast
4. **Brand alignment**: Images should reflect Ecosia's environmental mission
5. **Variety**: Offer diverse nature scenes (forest, ocean, mountains, desert, etc.)

## Default Wallpaper Strategy

### Option 1: No Default (Recommended)
- Don't set a default wallpaper
- Users see the standard Firefox homepage without a wallpaper
- Let users discover and choose their preferred wallpaper

### Option 2: Ecosia Default
- Set an Ecosia wallpaper as default for new users
- Could use a special "ecosia-default" wallpaper
- Downloads on first launch

### Option 3: Bundled Fallback
- Include one wallpaper in the app bundle as fallback
- Use it until user selects a different one
- Requires minimal code to check for bundled asset first

**Recommendation**: Start with Option 1 (no default) for simplicity. Add default later if user research shows it's valuable.

## Implementation Phases

### Phase 1: Infrastructure Setup (1-2 days)
- [ ] Set up CDN/hosting for wallpaper assets
- [ ] Create directory structure
- [ ] Test CORS and caching headers
- [ ] Verify HTTPS configuration

### Phase 2: Asset Creation (Design team - 1 week)
- [ ] Create 3-5 wallpaper sets (4 images each = 12-20 total images)
- [ ] Define color schemes for each wallpaper
- [ ] Optimize images for web delivery
- [ ] Test on various device sizes

### Phase 3: Metadata & Deployment (1 day)
- [ ] Create wallpapers.json metadata file
- [ ] Upload all assets to CDN
- [ ] Verify URLs are accessible
- [ ] Test JSON parsing

### Phase 4: App Configuration (1 day)
- [ ] Update `MOZ_WALLPAPER_ASSET_URL` in build config
- [ ] Build and test on device
- [ ] Verify wallpaper downloads work
- [ ] Test wallpaper selection UI

### Phase 5: Testing & QA (2-3 days)
- [ ] Test on iPhone (various models)
- [ ] Test on iPad (various models)
- [ ] Test orientation changes
- [ ] Test offline behavior (cached wallpapers)
- [ ] Verify color schemes look good with UI elements

### Phase 6: Launch (Included in app release)
- [ ] Deploy to production CDN
- [ ] Monitor CDN bandwidth usage
- [ ] Collect user feedback

**Total Timeline**: ~2 weeks (mostly design work)

## Testing Strategy

### Functional Testing
- [ ] Wallpaper selector appears in Settings
- [ ] Wallpapers download successfully
- [ ] Correct image shown for device type (iPhone vs iPad)
- [ ] Correct image shown for orientation (portrait vs landscape)
- [ ] Wallpaper persists after app restart
- [ ] Works offline after initial download

### Visual Testing
- [ ] Text remains readable with chosen colors
- [ ] Cards have appropriate opacity/color
- [ ] Logo color works with background
- [ ] No visual glitches during orientation change
- [ ] Images look sharp on all device resolutions

### Edge Cases
- [ ] Network failure during download (graceful failure)
- [ ] Corrupted image data (error handling)
- [ ] Invalid metadata JSON (fallback behavior)
- [ ] Very slow network (loading states)

## Cost Estimate

### Infrastructure
- **CDN bandwidth**: ~10-15 MB per user (initial download of 4 images)
- **Storage**: Minimal (~50MB for all wallpapers)
- **Estimated monthly cost**: $10-50 depending on user base and CDN provider

### Development
- **Engineering**: 2-3 days (mostly configuration and testing)
- **Design**: 5-7 days (creating optimized assets)
- **QA**: 2-3 days
- **Total**: ~2 weeks effort

## Monitoring & Analytics

### Metrics to Track
1. **Wallpaper engagement rate** - % of users who download wallpapers
2. **Most popular wallpapers** - Which designs resonate most
3. **Download success rate** - Network reliability
4. **CDN bandwidth usage** - Cost management

### Implementation
Use existing Firefox telemetry system:
- Track wallpaper selection events
- Monitor download failures
- Measure time to download

## Scaling Considerations

### Adding New Wallpapers
1. Design new wallpaper set (4 images)
2. Upload to CDN
3. Update wallpapers.json metadata
4. Users automatically see new wallpapers in selector

**No app update needed!**

### Seasonal Collections
Can add time-limited collections using `availability-range`:
```json
{
  "id": "ecosia-winter",
  "availability-range": {
    "start": "2026-12-01",
    "end": "2027-03-01"
  }
}
```

### Localized Collections
Can target specific regions using `available-locales`:
```json
{
  "id": "ecosia-europe",
  "available-locales": ["en-GB", "de-DE", "fr-FR"]
}
```

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|-----------|
| **CDN costs** | Low | Monitor usage; optimize image compression |
| **Network dependency** | Medium | Images cached locally after first download |
| **Asset file size** | Low | Target ~500KB per image with JPG compression |
| **Design resources** | Medium | Clear specs provided; reuse Firefox patterns |

## Questions for Product/Design

1. **How many wallpapers for initial launch?** (Recommend: 3-5)
2. **Should we set a default wallpaper?** (Recommend: No)
3. **What nature themes align with Ecosia brand?** (forest, ocean, mountains, etc.)
4. **Do we need seasonal/limited-time wallpapers?**
5. **Should wallpapers showcase Ecosia impact?** (tree counter, etc.)

## Success Criteria

✅ Users can select from multiple Ecosia wallpapers
✅ Wallpapers look great in all orientations
✅ Wallpapers work offline after initial download
✅ Zero code changes to Firefox wallpaper system
✅ Wallpapers can be updated without app releases

## Next Steps

1. **Decision**: Approve approach and timeline
2. **Kickoff**: Align with design team on wallpaper themes
3. **Infrastructure**: Set up CDN hosting
4. **Design**: Create initial 3-5 wallpaper sets
5. **Deploy**: Upload assets and configure app
6. **Test**: QA on devices
7. **Launch**: Ship with next app release

## Reference: Firefox Test JSON Example

From `firefox-ios-tests/.../wallpaperGoodData.json`:

```json
{
    "last-updated-date": "2001-02-03",
    "collections": [
        {
            "id": "firefox",
            "description": null,
            "heading": null,
            "learn-more-url": "https://www.mozilla.com",
            "available-locales": ["en-US", "es-US", "en-CA", "fr-CA"],
            "availability-range": {
                "start": "2002-11-28",
                "end": "2022-09-10"
            },
            "wallpapers": [
                {
                    "id": "beachVibes",
                    "text-color": "ADD8E6",
                    "card-color": "ADD8E6",
                    "logo-text-color": "ADD8E6"
                }
            ]
        }
    ]
}
```

## URL Structure Reference

Based on `WallpaperURLProvider.swift`:

**Metadata URL:**
```
{BASE_URL}/metadata/v1/wallpapers.json
```

**Image URLs:**
```
{BASE_URL}/ios/{wallpaperId}/{wallpaperId}_iPhone_portrait.jpg
{BASE_URL}/ios/{wallpaperId}/{wallpaperId}_iPhone_landscape.jpg
{BASE_URL}/ios/{wallpaperId}/{wallpaperId}_iPad_portrait.jpg
{BASE_URL}/ios/{wallpaperId}/{wallpaperId}_iPad_landscape.jpg
```

Where `{BASE_URL}` is the value of `MOZ_WALLPAPER_ASSET_URL` environment variable.

## Related Documentation

- [Wallpaper Configuration Analysis](./wallpaper-configuration-analysis.md) - Deep dive into system architecture
- [Product Pitch](./ecosia-wallpaper-product-pitch.md) - Business case for PM/Designer
- [Firefox iOS Wallpapers Wiki](https://github.com/mozilla-mobile/firefox-ios/wiki/Wallpapers) - Official Mozilla documentation
