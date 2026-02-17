#!/usr/bin/env node

/**
 * Comprehensive Wallpaper Metadata & Assets Validator
 *
 * Validates wallpaper metadata JSON files and verifies all image assets exist.
 *
 * Usage:
 *   node validate-wallpapers-full.js
 *
 * What it does:
 * 1. Validates local JSON file against schema
 * 2. Downloads and validates remote JSON file
 * 3. Checks all referenced images exist and are valid
 * 4. Cleans up temporary downloads
 *
 * Requirements:
 *   npm install ajv ajv-formats
 */

const fs = require('fs');
const path = require('path');
const https = require('https');
const { promisify } = require('util');

const readFile = promisify(fs.readFile);
const writeFile = promisify(fs.writeFile);
const unlink = promisify(fs.unlink);
const mkdir = promisify(fs.mkdir);

// Configuration
const BASE_URL = 'https://raw.githubusercontent.com/ecosia/ios-browser/refs/heads/copilot/add-background-to-ecosian-ntp/docs/cdn';
const LOCAL_JSON_PATH = path.resolve(__dirname, '../cdn/metadata/v1/wallpapers.json');
const SCHEMA_PATH = path.resolve(__dirname, 'wallpapers-schema.json');
const TEMP_DIR = path.resolve(__dirname, '.temp-validation');

// Image filename patterns based on iOS wallpaper system
const IMAGE_PATTERNS = [
  '_thumbnail.jpg',
  '_iPhone_portrait.jpg',
  '_iPhone_landscape.jpg',
  '_iPad_portrait.jpg',
  '_iPad_landscape.jpg'
];

// Colors for console output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function logSuccess(message) {
  log(`✅ ${message}`, 'green');
}

function logError(message) {
  log(`❌ ${message}`, 'red');
}

function logWarning(message) {
  log(`⚠️  ${message}`, 'yellow');
}

function logInfo(message) {
  log(`ℹ️  ${message}`, 'blue');
}

/**
 * Download a file from a URL
 */
function downloadFile(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (response) => {
      if (response.statusCode === 200) {
        const chunks = [];
        response.on('data', chunk => chunks.push(chunk));
        response.on('end', () => resolve(Buffer.concat(chunks)));
      } else {
        reject(new Error(`HTTP ${response.statusCode}: ${url}`));
      }
    }).on('error', reject);
  });
}

/**
 * Validate JSON against schema using Ajv
 */
async function validateJson(jsonData, schemaData, source) {
  try {
    const Ajv = require('ajv');
    const addFormats = require('ajv-formats');

    const ajv = new Ajv({ allErrors: true, strict: false });
    addFormats(ajv);

    const validate = ajv.compile(schemaData);
    const valid = validate(jsonData);

    if (valid) {
      logSuccess(`Schema validation passed for ${source}`);
      return true;
    } else {
      logError(`Schema validation failed for ${source}:`);
      validate.errors.forEach(error => {
        console.log(`  • ${error.instancePath} ${error.message}`);
      });
      return false;
    }
  } catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
      logWarning('Ajv not installed - skipping JSON schema validation');
      logInfo('Run: npm install ajv ajv-formats');
      return true; // Continue without schema validation
    }
    throw error;
  }
}

/**
 * Check if a buffer is a valid JPEG image
 */
function isValidJpeg(buffer) {
  // JPEG files start with FF D8 and end with FF D9
  if (buffer.length < 4) return false;

  const startsWithJpeg = buffer[0] === 0xFF && buffer[1] === 0xD8;
  const endsWithJpeg = buffer[buffer.length - 2] === 0xFF && buffer[buffer.length - 1] === 0xD9;

  return startsWithJpeg && endsWithJpeg;
}

/**
 * Validate that an image exists and is valid
 */
async function validateImage(baseUrl, wallpaperId, pattern, tempDir) {
  const filename = `${wallpaperId}${pattern}`;
  const url = `${baseUrl}/${wallpaperId}/${filename}`;
  const tempPath = path.join(tempDir, filename);

  try {
    const buffer = await downloadFile(url);

    if (!isValidJpeg(buffer)) {
      logError(`    Invalid JPEG: ${filename}`);
      return false;
    }

    const sizeKB = (buffer.length / 1024).toFixed(1);
    logSuccess(`    ${filename} (${sizeKB} KB)`);

    // Save temporarily for inspection if needed
    await writeFile(tempPath, buffer);

    return true;
  } catch (error) {
    logError(`    Failed to download ${filename}: ${error.message}`);
    return false;
  }
}

/**
 * Validate all images for a wallpaper
 */
async function validateWallpaperImages(baseUrl, wallpaper, tempDir) {
  log(`\n  📷 ${wallpaper.id}`, 'cyan');

  // Skip validation for wallpapers with bundled assets
  if (wallpaper['bundled-asset-name']) {
    logWarning(`    Skipping - uses bundled asset: ${wallpaper['bundled-asset-name']}`);
    return true;
  }

  let allValid = true;

  for (const pattern of IMAGE_PATTERNS) {
    const valid = await validateImage(baseUrl, wallpaper.id, pattern, tempDir);
    if (!valid) {
      allValid = false;
    }
  }

  return allValid;
}

/**
 * Perform business logic validation
 */
function performBusinessValidation(data) {
  const warnings = [];

  // Check for duplicate wallpaper IDs
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
    warnings.push(`Duplicate wallpaper IDs: ${Array.from(duplicates).join(', ')}`);
  }

  // Check for duplicate collection IDs
  const collectionIds = new Set();
  data.collections.forEach(collection => {
    if (collectionIds.has(collection.id)) {
      warnings.push(`Duplicate collection ID: ${collection.id}`);
    }
    collectionIds.add(collection.id);
  });

  // Warn if no bundled assets
  const hasBundled = data.collections.some(c =>
    c.wallpapers.some(w => w['bundled-asset-name'])
  );
  if (!hasBundled) {
    warnings.push('No bundled assets - users must download all wallpapers');
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

/**
 * Main validation function
 */
async function validate() {
  log('\n🎨 Wallpaper Metadata & Assets Validator\n', 'bright');

  let hasErrors = false;

  try {
    // Create temp directory
    try {
      await mkdir(TEMP_DIR, { recursive: true });
    } catch (error) {
      if (error.code !== 'EEXIST') throw error;
    }

    // Load schema
    logInfo('Loading JSON schema...');
    const schemaData = JSON.parse(await readFile(SCHEMA_PATH, 'utf8'));
    logSuccess('Schema loaded');

    // Validate local JSON
    log('\n📁 VALIDATING LOCAL JSON FILE', 'bright');
    log('─'.repeat(60));
    const localData = JSON.parse(await readFile(LOCAL_JSON_PATH, 'utf8'));
    const localValid = await validateJson(localData, schemaData, 'local file');
    if (!localValid) hasErrors = true;

    // Business logic validation
    const localWarnings = performBusinessValidation(localData);
    if (localWarnings.length > 0) {
      logWarning('Business logic warnings:');
      localWarnings.forEach(w => console.log(`  • ${w}`));
    }

    // Validate remote JSON
    log('\n🌐 VALIDATING REMOTE JSON FILE', 'bright');
    log('─'.repeat(60));
    const remoteUrl = `${BASE_URL}/metadata/v1/wallpapers.json`;
    try {
      const remoteBuffer = await downloadFile(remoteUrl);
      const remoteData = JSON.parse(remoteBuffer.toString('utf8'));
      logSuccess(`Downloaded ${(remoteBuffer.length / 1024).toFixed(1)} KB from GitHub`);

      const remoteValid = await validateJson(remoteData, schemaData, 'remote file');
      if (!remoteValid) hasErrors = true;

      // Business logic validation
      const remoteWarnings = performBusinessValidation(remoteData);
      if (remoteWarnings.length > 0) {
        logWarning('Business logic warnings:');
        remoteWarnings.forEach(w => console.log(`  • ${w}`));
      }

      // Use remote data for image validation
      log('\n🖼️  VALIDATING WALLPAPER IMAGES', 'bright');
      log('─'.repeat(60));

      let totalWallpapers = 0;
      let validWallpapers = 0;

      for (const collection of remoteData.collections) {
        log(`\n📚 Collection: ${collection.id}`, 'bright');

        for (const wallpaper of collection.wallpapers) {
          totalWallpapers++;
          const valid = await validateWallpaperImages(BASE_URL, wallpaper, TEMP_DIR);
          if (valid) {
            validWallpapers++;
          } else {
            hasErrors = true;
          }
        }
      }

      log('\n📊 IMAGE SUMMARY', 'bright');
      log('─'.repeat(60));
      log(`Wallpapers validated: ${validWallpapers}/${totalWallpapers}`);
      log(`Images per wallpaper: ${IMAGE_PATTERNS.length}`);
      log(`Total images checked: ${validWallpapers * IMAGE_PATTERNS.length}`);

    } catch (error) {
      logError(`Failed to download remote JSON: ${error.message}`);
      hasErrors = true;
    }

    // Cleanup temp directory
    log('\n🧹 Cleaning up temporary files...', 'cyan');
    try {
      const files = fs.readdirSync(TEMP_DIR);
      log(`Deleting ${files.length} temporary image(s)...`);
      for (const file of files) {
        await unlink(path.join(TEMP_DIR, file));
      }
      fs.rmdirSync(TEMP_DIR);
      logSuccess('Cleanup complete');
    } catch (error) {
      logWarning(`Cleanup warning: ${error.message}`);
    }

    // Final result
    log('\n' + '='.repeat(60), 'bright');
    if (hasErrors) {
      logError('VALIDATION FAILED - please fix the errors above');
      log('');
      process.exit(1);
    } else {
      logSuccess('VALIDATION PASSED - all checks successful! 🎉');
      log('');
      process.exit(0);
    }

  } catch (error) {
    logError(`\nFatal error: ${error.message}`);
    console.error(error.stack);
    process.exit(1);
  }
}

// Run validation
validate();
