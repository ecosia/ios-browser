# CDN Deployment Structure

This directory contains all files intended for CDN deployment to serve wallpaper assets to the Ecosia iOS app.

## Directory Structure

```
cdn/
├── metadata/v1/wallpapers.json  # Wallpaper metadata configuration
├── ecosia-mountains/            # Wallpaper image assets
├── ecosia-ocean/
├── spring-bloom/
└── autumn-leaves/
```

## Files

### Metadata

- **metadata/v1/wallpapers.json**: JSON configuration file containing wallpaper collections, availability dates, and image references
  - App fetches this file once per day to check for new wallpapers
  - Structure validated against JSON Schema (see `../ntp-backgrounds/wallpapers-schema.json`)

### Images

Each wallpaper directory contains 5 JPG image variants:

- `{id}_thumbnail.jpg` - Thumbnail for settings UI (200x200px)
- `{id}_iPhone_portrait.jpg` - iPhone portrait orientation
- `{id}_iPhone_landscape.jpg` - iPhone landscape orientation
- `{id}_iPad_portrait.jpg` - iPad portrait orientation
- `{id}_iPad_landscape.jpg` - iPad landscape orientation

**Example**: `ecosia-mountains/ecosia-mountains_thumbnail.jpg`

## CDN URLs

The app constructs URLs using the pattern defined in `WallpaperURLProvider.swift`:

- Metadata: `{base_url}/metadata/v1/wallpapers.json`
- Images: `{base_url}/{wallpaper-id}/{filename}.jpg`

Example: `https://cdn.example.com/ecosia-mountains/ecosia-mountains_thumbnail.jpg`

## Current Development Setup

For development and testing, the hardcoded URL in `WallpaperURLProvider.swift` points to:
```
https://raw.githubusercontent.com/ecosia/ios-browser/refs/heads/copilot/add-background-to-ecosian-ntp/docs
```

This should be replaced with the production CDN URL before merging.

## Production Deployment

### Requirements

1. **CDN endpoint** must support HTTPS
2. **CORS headers** may be needed for cross-origin requests
3. **Cache headers** should allow reasonable caching (e.g., 1 day for metadata, longer for images)
4. **Content-Type** headers:
   - `application/json` for wallpapers.json
   - `image/jpeg` for all .jpg files

### Deployment Checklist

- [ ] Upload all files maintaining directory structure
- [ ] Verify metadata JSON is accessible at `/metadata/v1/wallpapers.json`
- [ ] Verify all 35 image files are accessible
- [ ] Update `WallpaperURLProvider.swift` with production CDN URL
- [ ] Update `Info.plist` with `MozWallpaperURLScheme` key pointing to CDN base URL
- [ ] Test wallpaper downloads on physical devices

## Validation

Before deploying, validate both metadata and image assets:

```bash
cd ../ntp-backgrounds
npm install
node validate-wallpapers-full.js
```

This validates:
- ✅ JSON metadata against schema
- ✅ All referenced images exist on GitHub
- ✅ Images are valid JPEG files

See `../ntp-backgrounds/WALLPAPER-VALIDATION.md` for details.

## Documentation

All technical documentation, JSON schema, and validation scripts are in `../ntp-backgrounds/`:

- **[MOZILLA-FIREFOX-WALLPAPERS.md](../ntp-backgrounds/MOZILLA-FIREFOX-WALLPAPERS.md)** - Official Mozilla Firefox iOS wallpaper documentation
- **[Mozilla Firefox iOS Wallpapers Wiki](https://github.com/mozilla-mobile/firefox-ios/wiki/Wallpapers)** - Online reference
- `wallpapers-schema.json` - JSON Schema for metadata structure
- `WALLPAPER-VALIDATION.md` - Validation setup and usage guide
- `WALLPAPER-METADATA-REFRESH.md` - How metadata refresh works
- `validate-wallpapers-full.js` - Comprehensive validation script

## CDN Deployment Status

**✅ DEPLOYED TO CORE REPO**

These assets have been deployed to the Ecosia CDN infrastructure:

- **Repository:** `core` (Ecosia monorepo)
- **Branch:** `MOB-4105-add-mobile-wallpapers-to-cdn`
- **Location:** `static-files/assets/mobile-wallpapers/`
- **Commit:** 23a1494aa9
- **Date:** 2026-02-17

See [CDN-DEPLOYMENT.md](../ntp-backgrounds/CDN-DEPLOYMENT.md) for complete deployment documentation.

## Temporary Nature

**Note**: This directory may be removed from the ios-browser repository after successful production deployment, as CDN assets are now maintained in the core repository. It currently serves as:

1. ✅ Reference for CDN structure (deployed to core repo)
2. ⏳ Testing during development (until production CDN is live)
3. 📝 Documentation for expected file structure
