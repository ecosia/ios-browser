#!/usr/bin/env node

/**
 * Validates wallpapers.json against the JSON Schema
 *
 * Usage:
 *   node validate-wallpapers.js
 *
 * Requirements:
 *   npm install ajv ajv-formats
 */

const Ajv = require('ajv');
const addFormats = require('ajv-formats');
const fs = require('fs');
const path = require('path');

// Initialize AJV with strict mode and formats
const ajv = new Ajv({
  allErrors: true,
  verbose: true,
  strict: false  // Allow $schema property
});
addFormats(ajv);

// Load schema and data
const schemaPath = path.join(__dirname, 'wallpapers-schema.json');
const dataPath = path.join(__dirname, '../cdn/metadata/v1/wallpapers.json');

console.log('🔍 Validating Ecosia Wallpaper Metadata...\n');

try {
  const schema = JSON.parse(fs.readFileSync(schemaPath, 'utf8'));
  const data = JSON.parse(fs.readFileSync(dataPath, 'utf8'));

  // Compile schema
  const validate = ajv.compile(schema);

  // Validate data
  const valid = validate(data);

  if (valid) {
    console.log('✅ Validation successful!\n');

    // Additional business logic checks
    const warnings = performBusinessValidation(data);

    if (warnings.length > 0) {
      console.log('⚠️  Warnings (non-breaking):');
      warnings.forEach(w => console.log(`   - ${w}`));
      console.log('');
    }

    // Summary
    const collections = data.collections.length;
    const totalWallpapers = data.collections.reduce((sum, c) => sum + c.wallpapers.length, 0);
    const bundledCount = data.collections.reduce((sum, c) =>
      sum + c.wallpapers.filter(w => w['bundled-asset-name']).length, 0);

    console.log('📊 Summary:');
    console.log(`   Collections: ${collections}`);
    console.log(`   Total wallpapers: ${totalWallpapers}`);
    console.log(`   Bundled assets: ${bundledCount}`);
    console.log(`   Last updated: ${data['last-updated-date']}`);

    process.exit(0);
  } else {
    console.log('❌ Validation failed!\n');
    console.log('Errors:');
    validate.errors.forEach(err => {
      console.log(`  ${err.instancePath} ${err.message}`);
      if (err.params) {
        console.log(`    Details: ${JSON.stringify(err.params)}`);
      }
    });
    process.exit(1);
  }
} catch (error) {
  console.error('💥 Fatal error:', error.message);
  process.exit(1);
}

/**
 * Performs additional business logic validation beyond schema
 */
function performBusinessValidation(data) {
  const warnings = [];

  // Check for duplicate IDs across all wallpapers
  const allIds = new Set();
  const duplicates = new Set();

  data.collections.forEach(collection => {
    collection.wallpapers.forEach(wallpaper => {
      if (allIds.has(wallpaper.id)) {
        duplicates.add(wallpaper.id);
      }
      allIds.add(wallpaper.id);
    });
  });

  if (duplicates.size > 0) {
    warnings.push(`Duplicate wallpaper IDs found: ${Array.from(duplicates).join(', ')}`);
  }

  // Check for duplicate collection IDs
  const collectionIds = new Set();
  data.collections.forEach(collection => {
    if (collectionIds.has(collection.id)) {
      warnings.push(`Duplicate collection ID: ${collection.id}`);
    }
    collectionIds.add(collection.id);
  });

  // Warn if no bundled assets (first launch won't have wallpapers)
  const hasBundled = data.collections.some(c =>
    c.wallpapers.some(w => w['bundled-asset-name'])
  );
  if (!hasBundled) {
    warnings.push('No bundled assets found - users will need to download all wallpapers');
  }

  // Check if last-updated-date is in the future
  const lastUpdated = new Date(data['last-updated-date']);
  const now = new Date();
  if (lastUpdated > now) {
    warnings.push(`Last updated date is in the future: ${data['last-updated-date']}`);
  }

  // Validate availability ranges
  data.collections.forEach(collection => {
    if (collection['availability-range']) {
      const range = collection['availability-range'];
      if (range.start && range.end) {
        const start = new Date(range.start);
        const end = new Date(range.end);
        if (start >= end) {
          warnings.push(`Collection '${collection.id}' has invalid date range (start >= end)`);
        }
      }
    }
  });

  return warnings;
}
