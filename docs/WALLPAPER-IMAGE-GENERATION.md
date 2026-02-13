# Wallpaper Image Generation Process

This document explains how wallpaper images were sourced and structured for the Ecosia iOS app.

## Overview

The wallpaper system supports two types of images:
1. **Bundled assets** - Images included in the app bundle for offline-first experience
2. **Downloadable images** - Images hosted on CDN that are downloaded on-demand

## Image Sources

### Bundled Asset: `ntpBackground`

**Location:** `firefox-ios/Client/Ecosia/UI/Ecosia.xcassets/ntpBackground.imageset/`

**Files:**
- `wallpaper-nature.png` (1x)
- `wallpaper-nature@2x.png` (2x)
- `wallpaper-nature@3x.png` (3x)

**Usage:** Used for `ecosia-forest` wallpaper as the default bundled option.

### Downloadable Images: Cat Images from cataas.com

**Source:** https://cataas.com/cat (Random Cat as a Service API)

**Wallpapers using cat images:**
- `ecosia-ocean`
- `ecosia-mountains`
- `spring-bloom`
- `autumn-leaves`

## How Images Were Downloaded

### Command Structure

For each wallpaper, 5 images were downloaded with specific dimensions:

```bash
# Navigate to CDN directory
cd docs/cdn/ios

# Download images for a wallpaper (example: ecosia-ocean)
WALLPAPER_ID="ecosia-ocean"

# iPhone Portrait (3x resolution for iPhone 14 Pro Max)
curl -s "https://cataas.com/cat?width=1170&height=2532" \
  -o ${WALLPAPER_ID}/${WALLPAPER_ID}_iPhone_portrait.jpg

# iPhone Landscape
curl -s "https://cataas.com/cat?width=2532&height=1170" \
  -o ${WALLPAPER_ID}/${WALLPAPER_ID}_iPhone_landscape.jpg

# iPad Portrait (2x resolution for iPad Pro 12.9")
curl -s "https://cataas.com/cat?width=2048&height=2732" \
  -o ${WALLPAPER_ID}/${WALLPAPER_ID}_iPad_portrait.jpg

# iPad Landscape
curl -s "https://cataas.com/cat?width=2732&height=2048" \
  -o ${WALLPAPER_ID}/${WALLPAPER_ID}_iPad_landscape.jpg

# Thumbnail (for wallpaper selector UI)
curl -s "https://cataas.com/cat?width=200&height=200" \
  -o ${WALLPAPER_ID}/${WALLPAPER_ID}_thumbnail.jpg
```

### Full Download Script

```bash
#!/bin/bash
cd docs/cdn/ios

for WALLPAPER_ID in ecosia-ocean ecosia-mountains spring-bloom autumn-leaves; do
  echo "Downloading images for $WALLPAPER_ID..."

  mkdir -p "$WALLPAPER_ID"

  curl -s "https://cataas.com/cat?width=1170&height=2532" \
    -o "${WALLPAPER_ID}/${WALLPAPER_ID}_iPhone_portrait.jpg"

  curl -s "https://cataas.com/cat?width=2532&height=1170" \
    -o "${WALLPAPER_ID}/${WALLPAPER_ID}_iPhone_landscape.jpg"

  curl -s "https://cataas.com/cat?width=2048&height=2732" \
    -o "${WALLPAPER_ID}/${WALLPAPER_ID}_iPad_portrait.jpg"

  curl -s "https://cataas.com/cat?width=2732&height=2048" \
    -o "${WALLPAPER_ID}/${WALLPAPER_ID}_iPad_landscape.jpg"

  curl -s "https://cataas.com/cat?width=200&height=200" \
    -o "${WALLPAPER_ID}/${WALLPAPER_ID}_thumbnail.jpg"

  echo "✓ Downloaded 5 images for $WALLPAPER_ID"
done
```

## Image Dimensions Reference

### iPhone Images

Based on iPhone 14 Pro Max (3x resolution):

| Orientation | Dimensions | File Size Target |
|-------------|-----------|------------------|
| Portrait | 1170 × 2532 px | ~500KB - 1MB |
| Landscape | 2532 × 1170 px | ~500KB - 1MB |

### iPad Images

Based on iPad Pro 12.9" (2x resolution):

| Orientation | Dimensions | File Size Target |
|-------------|-----------|------------------|
| Portrait | 2048 × 2732 px | ~800KB - 1.5MB |
| Landscape | 2732 × 2048 px | ~800KB - 1.5MB |

### Thumbnails

| Size | File Size Target |
|------|------------------|
| 200 × 200 px | ~10KB - 50KB |

## Directory Structure

```
docs/cdn/ios/
├── ecosia-forest/          # Uses bundled asset, no files here
├── ecosia-ocean/
│   ├── ecosia-ocean_iPhone_portrait.jpg
│   ├── ecosia-ocean_iPhone_landscape.jpg
│   ├── ecosia-ocean_iPad_portrait.jpg
│   ├── ecosia-ocean_iPad_landscape.jpg
│   └── ecosia-ocean_thumbnail.jpg
├── ecosia-mountains/
│   ├── ecosia-mountains_iPhone_portrait.jpg
│   ├── ecosia-mountains_iPhone_landscape.jpg
│   ├── ecosia-mountains_iPad_portrait.jpg
│   ├── ecosia-mountains_iPad_landscape.jpg
│   └── ecosia-mountains_thumbnail.jpg
├── spring-bloom/
│   ├── spring-bloom_iPhone_portrait.jpg
│   ├── spring-bloom_iPhone_landscape.jpg
│   ├── spring-bloom_iPad_portrait.jpg
│   ├── spring-bloom_iPad_landscape.jpg
│   └── spring-bloom_thumbnail.jpg
└── autumn-leaves/
    ├── autumn-leaves_iPhone_portrait.jpg
    ├── autumn-leaves_iPhone_landscape.jpg
    ├── autumn-leaves_iPad_portrait.jpg
    ├── autumn-leaves_iPad_landscape.jpg
    └── autumn-leaves_thumbnail.jpg
```

## Metadata Configuration

### Bundled Asset (ecosia-forest)

```json
{
  "id": "ecosia-forest",
  "text-color": "FFFFFF",
  "card-color": "1A4D2E",
  "logo-text-color": "E8F5E9",
  "bundled-asset-name": "ntpBackground"
}
```

The `bundled-asset-name` field tells the app to use the bundled asset instead of downloading.

### Downloadable Images (others)

```json
{
  "id": "ecosia-ocean",
  "text-color": "FFFFFF",
  "card-color": "1B4965",
  "logo-text-color": "CAE9FF"
}
```

No `bundled-asset-name` field means the app will construct download URLs based on the wallpaper ID.

## URL Construction

The app constructs URLs using this pattern:

```
{BASE_URL}/ios/{wallpaperId}/{wallpaperId}_{device}_{orientation}.jpg
```

**Examples:**
```
https://raw.githubusercontent.com/.../docs/cdn/ios/ecosia-ocean/ecosia-ocean_iPhone_portrait.jpg
https://raw.githubusercontent.com/.../docs/cdn/ios/ecosia-ocean/ecosia-ocean_iPad_landscape.jpg
https://raw.githubusercontent.com/.../docs/cdn/ios/spring-bloom/spring-bloom_thumbnail.jpg
```

## Why Cat Images?

Cat images from cataas.com were used for **development and testing purposes**:

1. ✅ **Free and unlimited** - No licensing concerns
2. ✅ **Random variety** - Each download gets a different cat
3. ✅ **Dimension control** - API supports width/height parameters
4. ✅ **No authentication** - Simple curl commands
5. ✅ **Placeholder content** - Easy to replace with production images later

## Replacing with Production Images

To use real nature/environment images in production:

1. **Source images** from:
   - Unsplash (https://unsplash.com) - Free high-quality photos
   - Pexels (https://pexels.com) - Free stock photos
   - Ecosia's own photography
   - Design team custom creations

2. **Resize to required dimensions** using:
   - ImageMagick: `convert input.jpg -resize 1170x2532^ -gravity center -extent 1170x2532 output.jpg`
   - Photoshop/Sketch/Figma
   - Online tools like squoosh.app

3. **Optimize for web**:
   - Use JPG format
   - 85% quality setting
   - Strip metadata
   - Target file sizes as shown in tables above

4. **Replace files** in `docs/cdn/ios/{wallpaper-id}/` directories

5. **Update last-updated-date** in `docs/cdn/metadata/v1/wallpapers.json`

6. **Test** in app - app will re-download on next metadata check

## Validation

After adding/replacing images, validate:

```bash
# Check file sizes
ls -lh docs/cdn/ios/*/

# Verify all required files exist
for id in ecosia-ocean ecosia-mountains spring-bloom autumn-leaves; do
  echo "Checking $id..."
  ls docs/cdn/ios/$id/${id}_iPhone_portrait.jpg
  ls docs/cdn/ios/$id/${id}_iPhone_landscape.jpg
  ls docs/cdn/ios/$id/${id}_iPad_portrait.jpg
  ls docs/cdn/ios/$id/${id}_iPad_landscape.jpg
  ls docs/cdn/ios/$id/${id}_thumbnail.jpg
done

# Validate JSON schema
cd docs/ntp-backgrounds
npm run validate
```

## Notes

- Cat images are committed to the repository for testing
- GitHub raw URLs are used temporarily for development
- Production should use a proper CDN (CloudFront, Fastly, etc.)
- Images should be optimized before committing to keep repo size manageable
- Consider using Git LFS for binary assets in larger projects

## Related Documentation

- [Wallpaper Metadata](./ntp-backgrounds/README.md)
- [Wallpaper System Implementation](./ntp-backgrounds/ecosia-wallpaper-system-implementation-plan.md)
- [Metadata Refresh Logic](./ntp-backgrounds/WALLPAPER-METADATA-REFRESH.md)
