# CDN Deployment Structure

This directory contains all files intended for CDN deployment to serve wallpaper assets to the Ecosia iOS app.

## Directory Structure

```
cdn/
├── metadata/v1/wallpapers.json  # Wallpaper metadata configuration
└── ios/                         # Wallpaper image assets
    ├── ecosia-default/
    ├── ecosia-forest/
    ├── ecosia-ocean/
    ├── ecosia-mountains/
    ├── ecosia-desert/
    ├── spring-bloom/
    └── autumn-leaves/
```

## Files

### Metadata

- **metadata/v1/wallpapers.json**: JSON configuration file containing wallpaper collections, availability dates, and image references
  - App fetches this file once per day to check for new wallpapers
  - Structure validated against JSON Schema (see `../ntp-backgrounds/wallpapers-schema.json`)

### Images

Each wallpaper directory (under `ios/`) contains 5 JPG image variants:

- `{id}_thumbnail.jpg` - Thumbnail for settings UI (200x200px recommended)
- `{id}_iPhone_portrait.jpg` - iPhone portrait orientation
- `{id}_iPhone_landscape.jpg` - iPhone landscape orientation
- `{id}_iPad_portrait.jpg` - iPad portrait orientation
- `{id}_iPad_landscape.jpg` - iPad landscape orientation

**Total files**: 35 images (7 wallpapers × 5 variants each)

## CDN URLs

The app constructs URLs using the pattern defined in `WallpaperURLProvider.swift`:

- Metadata: `{base_url}/metadata/v1/wallpapers.json`
- Images: `{base_url}/ios/{wallpaper-id}/{filename}.jpg`

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

Before deploying, validate the metadata file:

```bash
cd ../ntp-backgrounds
npm install
node validate-wallpapers.js
```

See `../ntp-backgrounds/WALLPAPER-VALIDATION.md` for details.

## Documentation

All technical documentation, JSON schema, and validation scripts are in `../ntp-backgrounds/`:

- `wallpapers-schema.json` - JSON Schema for metadata structure
- `WALLPAPER-VALIDATION.md` - Validation setup and usage guide
- `WALLPAPER-METADATA-REFRESH.md` - How metadata refresh works
- `validate-wallpapers.js` - Validation script

## Temporary Nature

**Note**: This directory may be removed from the repository before merging, as CDN assets should be deployed separately from the app codebase. It serves as a reference for:

1. Backend team to understand expected CDN structure
2. Testing and development during feature implementation
3. Initial deployment preparation
