# Wallpaper Metadata Validation Guide

## Overview

The wallpaper metadata structure is documented using **JSON Schema**, the industry standard for describing JSON document structure (similar to XSD for XML).

## Files

- **[`wallpapers-schema.json`](./wallpapers-schema.json)** - JSON Schema defining structure and validation rules
- **[`metadata/v1/wallpapers.json`](./metadata/v1/wallpapers.json)** - Actual metadata consumed by iOS app
- **[`metadata/v1/validate-wallpapers.js`](./metadata/v1/validate-wallpapers.js)** - Validation script
- **[`metadata/v1/README.md`](./metadata/v1/README.md)** - Detailed validation documentation

## Quick Start

### 1. View the Schema Documentation

The JSON Schema serves as both documentation and validation:

**Option A: Read the JSON file directly**
```bash
cat docs/wallpapers-schema.json
```

**Option B: Use online viewers for better readability**
- [JSON Schema Viewer](https://json-schema.app/view) - Paste the schema for interactive docs
- [JSON Schema Validator](https://www.jsonschemavalidator.net/) - View and validate simultaneously

### 2. Validate Your JSON

**Setup (one-time):**
```bash
cd docs/metadata/v1
npm install
```

**Run validation:**
```bash
cd docs/metadata/v1
npm run validate
```

**Expected output:**
```
🔍 Validating Ecosia Wallpaper Metadata...

✅ Validation successful!

📊 Summary:
   Collections: 2
   Total wallpapers: 7
   Bundled assets: 5
   Last updated: 2026-02-12
```

## What Gets Validated

### Schema Validation (Strict - Must Pass)

✅ **Structure**
- Required fields: `last-updated-date`, `collections`, collection `id`, wallpaper `id`
- No extra/unknown properties allowed
- Correct nesting of objects and arrays

✅ **Data Types**
- Dates are strings in YYYY-MM-DD format
- Colors are 6-character hex strings (uppercase, no #)
- Locales match pattern: `en-US`, `pt-BR`, etc.
- IDs use lowercase, numbers, and hyphens only

✅ **Constraints**
- At least 1 collection required
- At least 1 wallpaper per collection
- Hex colors: exactly 6 characters (e.g., `FFFFFF`)
- Valid date formats for ranges

### Business Logic Validation (Warnings - Should Review)

⚠️ **Duplicates**
- Duplicate wallpaper IDs across collections
- Duplicate collection IDs

⚠️ **Date Issues**
- Future dates in `last-updated-date`
- Invalid ranges (start date after end date)

⚠️ **User Experience**
- No bundled assets (requires download on first launch)

## Schema Structure Reference

### Top Level

```json
{
  "last-updated-date": "2026-02-12",  // Required: YYYY-MM-DD
  "collections": [ /* array */ ]      // Required: At least 1 collection
}
```

### Collection Object

```json
{
  "id": "ecosia-nature",                    // Required: lowercase-with-hyphens
  "learn-more-url": "https://ecosia.org",   // Optional: URL or null
  "available-locales": ["en-US", "de-DE"],  // Optional: array or null
  "availability-range": {                   // Optional: object or null
    "start": "2026-03-01",                  // Optional: YYYY-MM-DD or null
    "end": "2026-05-31"                     // Optional: YYYY-MM-DD or null
  },
  "wallpapers": [ /* array */ ],            // Required: At least 1 wallpaper
  "heading": "Ecosia Nature",               // Optional: string or null
  "description": "Nature backgrounds"       // Optional: string or null
}
```

### Wallpaper Object

```json
{
  "id": "ecosia-default",              // Required: matches asset folder name
  "text-color": "FFFFFF",              // Required: 6-char hex (UPPERCASE)
  "card-color": "1A4D2E",              // Optional: 6-char hex (UPPERCASE)
  "logo-text-color": "E8F5E9",         // Optional: 6-char hex (UPPERCASE)
  "bundled-asset-name": "ntpBackground" // Optional: Ecosia extension
}
```

## Common Validation Errors

### ❌ Invalid hex color
```
/collections/0/wallpapers/0/text-color must match pattern "^[0-9A-F]{6}$"
```
**Fix:** Use uppercase 6-character hex without `#`: `"FFFFFF"` not `"#ffffff"`

### ❌ Invalid date format
```
/last-updated-date must match pattern "^\d{4}-\d{2}-\d{2}$"
```
**Fix:** Use YYYY-MM-DD format: `"2026-02-12"` not `"2026-2-12"` or `"12/02/2026"`

### ❌ Invalid ID format
```
/collections/0/id must match pattern "^[a-z0-9-]+$"
```
**Fix:** Use lowercase with hyphens: `"ecosia-nature"` not `"Ecosia_Nature"`

### ❌ Unknown property
```
/collections/0 must NOT have additional properties
```
**Fix:** Remove unknown fields or update schema if intentionally adding new field

## Integration Options

### Git Pre-commit Hook

Automatically validate before commits:

```bash
# .git/hooks/pre-commit
#!/bin/bash
if git diff --cached --name-only | grep -q "docs/metadata/v1/wallpapers.json"; then
  cd docs/metadata/v1 && npm run validate || exit 1
fi
```

### CI/CD (GitHub Actions)

```yaml
name: Validate Wallpaper Metadata
on:
  pull_request:
    paths: ['docs/metadata/v1/wallpapers.json']
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with: { node-version: '18' }
      - run: cd docs/metadata/v1 && npm install && npm run validate
```

### Manual Validation

```bash
# From project root
cd docs/metadata/v1
node validate-wallpapers.js

# Or using npm script
npm run validate
```

## Ecosia Extensions

The schema documents Ecosia-specific extensions to the Firefox wallpaper format:

### `bundled-asset-name` (Wallpaper Property)

Enables offline-first wallpaper experience:

```json
{
  "id": "ecosia-default",
  "text-color": "FFFFFF",
  "bundled-asset-name": "ntpBackground"  // ← Ecosia extension
}
```

**Purpose:** References an asset in the app bundle, allowing wallpapers to work immediately on first launch without downloading.

**Behavior:**
- If present: App uses bundled asset (offline-capable)
- If absent: App downloads from CDN (requires network)

## Further Reading

- **[Mozilla Firefox iOS Wallpapers](https://github.com/mozilla-mobile/firefox-ios/wiki/Wallpapers)** - Official Mozilla documentation ([local copy](./MOZILLA-FIREFOX-WALLPAPERS.md))
- **[JSON Schema Specification](https://json-schema.org/)** - Official standard
- **[README.md](./README.md)** - Main wallpaper documentation
- **[wallpapers-schema.json](./wallpapers-schema.json)** - JSON Schema definition

## Troubleshooting

**Q: Validation script won't run**
A: Install dependencies: `cd docs/metadata/v1 && npm install`

**Q: Schema looks valid but validation fails**
A: Check for:
- Trailing commas in JSON (not allowed)
- Lowercase hex colors (must be uppercase)
- Extra spaces in dates
- Wrong date format (must be YYYY-MM-DD)

**Q: How do I add a new field?**
A: Update both `docs/wallpapers-schema.json` and the Swift Codable structs

**Q: Do I need to validate locally?**
A: Highly recommended - catches errors before committing. Consider adding a pre-commit hook.
