# Wallpaper Metadata Documentation

This directory contains documentation, validation tooling, and reference files for the Ecosia NTP wallpaper system.

## Files

- **`wallpapers-schema.json`** - JSON Schema defining the structure and validation rules
- **`validate-wallpapers.js`** - Node.js script to validate the JSON against the schema
- **`package.json`** - Node.js dependencies for validation
- **`README.md`** - This file
- **`WALLPAPER-VALIDATION.md`** - Complete validation guide
- **`WALLPAPER-METADATA-REFRESH.md`** - Documentation on metadata refresh logic
- **`wallpaper-debug-logging.patch`** - Reference file with debug statements (removed from code)

## JSON Schema Documentation

The `wallpapers-schema.json` file documents the complete structure of the wallpaper metadata format, including:

- Field names, types, and constraints
- Required vs optional fields
- Pattern validation (hex colors, dates, IDs)
- Descriptions and examples for each field
- Ecosia-specific extensions (like `bundled-asset-name`)

**View the schema:** [wallpapers-schema.json](./wallpapers-schema.json)

**Online viewers:**
- Paste the schema into [JSON Schema Validator](https://www.jsonschemavalidator.net/)
- Use [JSON Schema Viewer](https://json-schema.app/view) for interactive docs

## Validation

### Setup (one-time)

```bash
cd docs/ntp-backgrounds
npm install
```

### Validate JSON

The validation script validates the metadata file at `../cdn/metadata/v1/wallpapers.json`:

```bash
npm run validate
```

Or directly:

```bash
node validate-wallpapers.js
```

### Example Output

**Success:**
```
🔍 Validating Ecosia Wallpaper Metadata...

✅ Validation successful!

📊 Summary:
   Collections: 2
   Total wallpapers: 7
   Bundled assets: 5
   Last updated: 2026-02-12
```

**Failure:**
```
🔍 Validating Ecosia Wallpaper Metadata...

❌ Validation failed!

Errors:
  /collections/0/wallpapers/0/text-color must match pattern "^[0-9A-F]{6}$"
    Details: {"pattern":"^[0-9A-F]{6}$"}
```

## Validation Checks

### Schema Validation (Strict)

- ✅ Required fields present
- ✅ Correct data types
- ✅ Valid date formats (YYYY-MM-DD)
- ✅ Valid hex colors (6 digits, uppercase)
- ✅ Valid locale codes (e.g., en-US)
- ✅ Valid IDs (lowercase, numbers, hyphens only)
- ✅ No additional unknown properties

### Business Logic Checks (Warnings)

- ⚠️ Duplicate wallpaper IDs across collections
- ⚠️ Duplicate collection IDs
- ⚠️ No bundled assets (users must download everything)
- ⚠️ Future dates in `last-updated-date`
- ⚠️ Invalid date ranges (start >= end)

## Integration with Git

### Pre-commit Hook (Recommended)

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash

# Validate wallpaper metadata before commit
if git diff --cached --name-only | grep -q "docs/cdn/metadata/v1/wallpapers.json"; then
  echo "Validating wallpaper metadata..."
  cd docs/ntp-backgrounds
  npm run validate || exit 1
fi
```

### GitHub Actions

Example workflow:

```yaml
name: Validate Wallpaper Metadata

on:
  pull_request:
    paths:
      - 'docs/cdn/metadata/v1/wallpapers.json'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: cd docs/ntp-backgrounds && npm install
      - run: cd docs/ntp-backgrounds && npm run validate
```

## Schema Reference

Based on [Firefox iOS Wallpapers Wiki](https://github.com/mozilla-mobile/firefox-ios/wiki/Wallpapers) with Ecosia extensions.

### Key Differences from Firefox

1. **`bundled-asset-name`** (Ecosia extension)
   - Optional field in wallpaper objects
   - Points to asset in app bundle for offline-first experience
   - Example: `"bundled-asset-name": "ntpBackground"`

2. **Collection ID conventions**
   - Firefox uses `"classic-firefox"` for default collection
   - Ecosia uses `"ecosia-nature"` (marked as classic in code)

3. **Asset naming**
   - Follows pattern: `{id}_thumbnail.jpg`, `{id}_iPhone_portrait.jpg`, etc.
   - See [Asset Structure](../../../docs/wallpaper-asset-structure.md)

## Troubleshooting

**Error: Cannot find module 'ajv'**
```bash
npm install
```

**Schema validation fails but JSON looks correct**
- Check for trailing commas (not allowed in JSON)
- Verify hex colors are UPPERCASE
- Ensure dates are YYYY-MM-DD format
- Check for extra properties not in schema

**Business validation warnings**
- These are non-breaking but should be reviewed
- Duplicate IDs may indicate copy-paste errors
- Missing bundled assets means poor first-launch experience
