# CDN2: Web Extension Wallpapers (iOS Format)

This directory contains wallpapers reverse-engineered from the Ecosia web extension, converted to iOS-compatible format.

## Source

- **Origin:** `core/web-extensions/common/static/wallpapers/`
- **Commit:** https://github.com/ecosia/core/commit/009c0f6177df5680b648f527b11d0f7fda40d433
- **Original Format:** AVIF (web extension optimized)
- **Converted Format:** JPEG (iOS optimized)

## Contents

### Collections (6 total)

1. **Abstract Nature** (7 wallpapers)
   - flower, forest, leaf, mountain, mushroom, soil, wood

2. **Ecosia Projects** (6 wallpapers - top level countries)
   - australia, ethiopia, india, senegal, spain, uganda

3. **Ecosia Projects: Brazil** (3 wallpapers)
   - brazil, brazil1, brazil2

4. **Ecosia Projects: Ghana** (3 wallpapers)
   - ghana, ghana1, ghana2

5. **Ecosia Projects: Kenya** (3 wallpapers)
   - kenya, kenya1, kenya2

6. **Ecosia Projects: Madagascar** (4 wallpapers)
   - madagascar, madagascar1, madagascar2, madagascar3

**Total:** 26 wallpapers, 130 image files (5 variants each)

## Flatmapping Strategy

The web extension uses nested folder structure:
```
ecosia-projects/
├── brazil/
│   ├── brazil.avif
│   ├── brazil1.avif
│   └── brazil2.avif
└── ghana/
    ├── ghana.avif
    ├── ghana1.avif
    └── ghana2.avif
```

For iOS, subfolders are "flatmapped" to collection names:
- `ecosia-projects/ghana` → **"Ecosia Projects: Ghana"** collection
- `ecosia-projects/brazil` → **"Ecosia Projects: Brazil"** collection

This avoids nested hierarchy in iOS UI while maintaining semantic grouping.

## File Structure

```
cdn2/
├── metadata/v1/wallpapers.json  # iOS metadata
├── flower/
│   ├── flower_thumbnail.jpg          (200x200px)
│   ├── flower_iPhone_portrait.jpg    (1170x2532px)
│   ├── flower_iPhone_landscape.jpg   (2532x1170px)
│   ├── flower_iPad_portrait.jpg      (2048x2732px)
│   └── flower_iPad_landscape.jpg     (2732x2048px)
├── ghana/
├── brazil/
└── ... (26 wallpaper directories)
```

## Image Specifications

Each wallpaper has 5 JPEG variants:

| Variant | Resolution | Device |
|---------|------------|--------|
| thumbnail | 200×200px | Settings UI |
| iPhone_portrait | 1170×2532px | iPhone 13 Pro portrait |
| iPhone_landscape | 2532×1170px | iPhone 13 Pro landscape |
| iPad_portrait | 2048×2732px | iPad Pro 12.9" portrait |
| iPad_landscape | 2732×2048px | iPad Pro 12.9" landscape |

- **Format:** JPEG, quality 85%
- **Conversion:** ImageMagick 7+, resize with center crop
- **Naming:** `{wallpaper-id}_{variant}.jpg`

## Metadata

`metadata/v1/wallpapers.json` follows iOS wallpaper schema (see `docs/ntp-backgrounds/wallpapers-schema.json`).

### Colors

All wallpapers use default Ecosia green theme:
- **text-color:** FFFFFF (white)
- **card-color:** 1A4D2E (Ecosia dark green)
- **logo-text-color:** E8F5E9 (light green)

These can be customized per wallpaper if needed.

## Conversion Process

The conversion was automated using `convert-web-wallpapers.js`:

```bash
cd docs/ntp-backgrounds
npm install sharp  # Initially tried Sharp (failed on most AVIF files)
brew install imagemagick  # Switched to ImageMagick (100% success)
node convert-web-wallpapers.js
```

### Conversion Steps

1. Parse `core/web-extensions/common/vue2/wallpaper-projects.json`
2. Extract wallpaper structure with flatmapping logic
3. Convert AVIF → JPEG using ImageMagick:
   - Resize to target dimensions
   - Center crop to fit aspect ratio
   - Save as JPEG with 85% quality
4. Generate iOS metadata JSON
5. Validate structure

### Results

```
✅ Collections: 6
✅ Wallpapers: 26
✅ Successful: 26 (100%)
❌ Errors: 0
✅ Total variants: 130
```

## File Sizes

| Wallpaper | Thumbnail | iPhone | iPad | Total |
|-----------|-----------|--------|------|-------|
| flower | 5KB | ~105KB | ~170KB | ~280KB |
| leaf | 9KB | ~295KB | ~503KB | ~807KB |
| madagascar3 | 17KB | ~688KB | ~1166KB | ~1.8MB |

Average per wallpaper: ~500KB across all 5 variants

## Validation

Validate the converted wallpapers:

```bash
cd docs/ntp-backgrounds
node validate-wallpapers-full.js
```

This validates:
- ✅ JSON metadata structure
- ✅ All 130 image files exist
- ✅ Images are valid JPEG files
- ✅ No duplicate wallpaper IDs

## Deployment

This directory (`cdn2`) can be deployed alongside the original `cdn` directory:

- **cdn/** - Original 5 handcrafted Ecosia wallpapers (ecosia-mountains, ecosia-ocean, etc.)
- **cdn2/** - 26 web extension wallpapers converted to iOS format

Both use the same iOS metadata structure and can coexist or be merged.

## Differences from Web Extension

| Aspect | Web Extension | iOS (CDN2) |
|--------|---------------|------------|
| Format | AVIF | JPEG |
| Variants | 3 (background, preview, thumbnail) | 5 (thumbnail + 4 device orientations) |
| Resolution | Responsive @1x/@2x | Fixed device-specific resolutions |
| Structure | Nested folders | Flat with collection naming |
| Metadata | Generated manifest | Static JSON |
| File size | ~30KB (AVIF) | ~500KB (JPEG, 5 variants) |

## Related Documentation

- **convert-web-wallpapers.js** - Conversion script (docs/ntp-backgrounds/)
- **wallpapers-schema.json** - iOS metadata schema
- **WALLPAPER-VALIDATION.md** - Validation guide
- **MOZILLA-FIREFOX-WALLPAPERS.md** - Mozilla's wallpaper documentation

## Future Updates

To add new wallpapers from web extension:

1. Update wallpapers in `core/web-extensions/common/static/wallpapers/`
2. Run conversion script: `node convert-web-wallpapers.js`
3. Validate: `node validate-wallpapers-full.js`
4. Deploy updated `cdn2/` directory
5. No iOS app update needed (metadata auto-refreshes daily)

---

**Last updated:** 2026-02-18
**Conversion tool:** convert-web-wallpapers.js
**Total wallpapers:** 26
**Total files:** 131 (130 images + 1 metadata JSON)
