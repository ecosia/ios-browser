#!/usr/bin/env node
/**
 * Convert Web Extension Wallpapers to iOS Format
 *
 * This script reverse engineers web extension wallpapers (AVIF format)
 * into iOS-compatible wallpaper structure (JPEG format with 5 variants).
 *
 * Usage:
 *   node convert-web-wallpapers.js
 *
 * Input:  core/web-extensions/common/static/wallpapers/
 * Output: ios-browser/docs/cdn2/
 *
 * Requirements:
 *   - ImageMagick (for AVIF to JPEG conversion)
 *   - Sharp npm package (alternative to ImageMagick)
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Configuration
const CORE_REPO = '/Users/falkorichter/Documents/core';
const IOS_REPO = '/Users/falkorichter/Documents/ios-browser-2026';
const SOURCE_PATH = path.join(CORE_REPO, 'web-extensions/common/static/wallpapers');
const OUTPUT_PATH = path.join(IOS_REPO, 'docs/cdn2');
const MANIFEST_PATH = path.join(CORE_REPO, 'web-extensions/common/vue2/wallpaper-projects.json');

// iOS image specifications
const IOS_VARIANTS = {
  thumbnail: { width: 200, height: 200 },
  iPhone_portrait: { width: 1170, height: 2532 },  // iPhone 13 Pro
  iPhone_landscape: { width: 2532, height: 1170 },
  iPad_portrait: { width: 2048, height: 2732 },   // iPad Pro 12.9"
  iPad_landscape: { width: 2732, height: 2048 }
};

/**
 * Parse the web extension manifest to understand structure
 */
function parseWebManifest() {
  console.log('📖 Reading web extension manifest...');
  const manifest = JSON.parse(fs.readFileSync(MANIFEST_PATH, 'utf8'));

  const collections = [];
  const wallpapers = [];

  for (const item of manifest.wallpapers) {
    if (item.type === 'image' && item.id === 'default') {
      // Default wallpaper - add to its own collection or skip
      console.log(`  ⏭️  Skipping default wallpaper`);
      continue;
    }

    if (item.type === 'folder') {
      const collectionName = formatCollectionName(item.title || item.key);
      console.log(`  📁 Found collection: ${collectionName}`);

      const collectionWallpapers = parseCollectionItems(item, collectionName);
      wallpapers.push(...collectionWallpapers);

      if (collectionWallpapers.length > 0) {
        collections.push({
          id: item.key,
          name: collectionName,
          wallpaperIds: collectionWallpapers.map(w => w.id)
        });
      }
    }
  }

  console.log(`\n✅ Found ${collections.length} collections with ${wallpapers.length} wallpapers`);
  return { collections, wallpapers };
}

/**
 * Parse items in a collection (handles nested folders)
 */
function parseCollectionItems(folder, parentName, subfolderName = null) {
  const wallpapers = [];

  for (const item of folder.items) {
    if (item.type === 'image') {
      // Single image in collection
      const wallpaper = {
        id: item.id,
        title: formatTitle(item.title || item.id),
        collectionName: subfolderName ? `${parentName}: ${formatTitle(subfolderName)}` : parentName,
        sourcePath: item.background.src.replace('static/wallpapers/backgrounds/', ''),
        thumbnailPath: item.thumbnail.src.replace('static/wallpapers/thumbnails/', '')
      };
      wallpapers.push(wallpaper);
      console.log(`    🖼️  ${wallpaper.collectionName} - ${wallpaper.title} (${wallpaper.id})`);
    } else if (item.type === 'folder') {
      // Nested folder - flatmap to "Collection: Subfolder"
      const subfolder = item.title || item.key;
      console.log(`    📂 Found subfolder: ${subfolder}`);

      for (const subItem of item.images) {
        const wallpaper = {
          id: subItem.id,
          title: formatTitle(subItem.title || subItem.id),
          collectionName: `${parentName}: ${formatTitle(subfolder)}`,
          sourcePath: subItem.background.src.replace('static/wallpapers/backgrounds/', ''),
          thumbnailPath: subItem.thumbnail.src.replace('static/wallpapers/thumbnails/', '')
        };
        wallpapers.push(wallpaper);
        console.log(`      🖼️  ${wallpaper.collectionName} - ${wallpaper.title} (${wallpaper.id})`);
      }
    }
  }

  return wallpapers;
}

/**
 * Format collection name for display
 */
function formatCollectionName(name) {
  return name
    .split(/[-_]/)
    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}

/**
 * Format wallpaper title
 */
function formatTitle(title) {
  // Handle numbered variants (e.g., "ghana1" -> "Ghana 1")
  const match = title.match(/^([a-z]+)(\d+)$/);
  if (match) {
    const base = match[1].charAt(0).toUpperCase() + match[1].slice(1);
    return `${base} ${match[2]}`;
  }
  return title.charAt(0).toUpperCase() + title.slice(1);
}

/**
 * Convert AVIF to JPEG using ImageMagick
 */
function convertAvifToJpeg(sourcePath, outputPath, width, height) {
  const absSourcePath = path.join(SOURCE_PATH, 'backgrounds', sourcePath);

  let sourceFile = absSourcePath;
  if (!fs.existsSync(absSourcePath)) {
    // Try @2x version
    const source2x = sourcePath.replace('.avif', '@2x.avif');
    const absSource2x = path.join(SOURCE_PATH, 'backgrounds', source2x);
    if (fs.existsSync(absSource2x)) {
      sourceFile = absSource2x;
    } else {
      throw new Error(`Source file not found: ${absSourcePath}`);
    }
  }

  try {
    // Use magick command (ImageMagick 7+)
    const cmd = `magick "${sourceFile}" -resize ${width}x${height}^ -gravity center -extent ${width}x${height} -quality 85 "${outputPath}"`;
    execSync(cmd, { stdio: 'pipe' });
  } catch (error) {
    throw new Error(`ImageMagick conversion failed: ${error.message}`);
  }
}

/**
 * Generate iOS variants for a wallpaper
 */
function generateIosVariants(wallpaper, dryRun = false) {
  const wallpaperDir = path.join(OUTPUT_PATH, wallpaper.id);

  if (!dryRun) {
    fs.mkdirSync(wallpaperDir, { recursive: true });
  }

  console.log(`\n🎨 Processing: ${wallpaper.id}`);
  console.log(`   Collection: ${wallpaper.collectionName}`);
  console.log(`   Source: ${wallpaper.sourcePath}`);

  const variants = [];

  for (const [variantName, dimensions] of Object.entries(IOS_VARIANTS)) {
    const filename = `${wallpaper.id}_${variantName}.jpg`;
    const outputPath = path.join(wallpaperDir, filename);

    if (!dryRun) {
      try {
        convertAvifToJpeg(wallpaper.sourcePath, outputPath, dimensions.width, dimensions.height);
        const stats = fs.statSync(outputPath);
        console.log(`   ✅ ${variantName}: ${filename} (${Math.round(stats.size / 1024)}KB)`);
      } catch (error) {
        console.log(`   ❌ ${variantName}: ${error.message}`);
      }
    } else {
      console.log(`   🔍 ${variantName}: ${filename} (${dimensions.width}x${dimensions.height})`);
    }

    variants.push({ variant: variantName, filename, ...dimensions });
  }

  return variants;
}

/**
 * Generate iOS metadata JSON
 */
function generateIosMetadata(collections, wallpapers) {
  console.log('\n📝 Generating iOS metadata JSON...');

  const metadata = {
    'last-updated-date': new Date().toISOString().split('T')[0],
    collections: []
  };

  // Group wallpapers by collection
  const collectionMap = new Map();

  for (const wallpaper of wallpapers) {
    if (!collectionMap.has(wallpaper.collectionName)) {
      collectionMap.set(wallpaper.collectionName, []);
    }
    collectionMap.get(wallpaper.collectionName).push(wallpaper);
  }

  // Create collection entries
  for (const [collectionName, collectionWallpapers] of collectionMap.entries()) {
    const collectionId = collectionName.toLowerCase().replace(/[^a-z0-9]+/g, '-');

    metadata.collections.push({
      id: collectionId,
      'learn-more-url': 'https://ecosia.org',
      'available-locales': null,
      'availability-range': null,
      wallpapers: collectionWallpapers.map(w => ({
        id: w.id,
        'text-color': 'FFFFFF',
        'card-color': '1A4D2E',
        'logo-text-color': 'E8F5E9'
      })),
      heading: collectionName,
      description: `${collectionName} wallpapers`
    });
  }

  console.log(`✅ Generated metadata for ${metadata.collections.length} collections`);
  return metadata;
}

/**
 * Main conversion process
 */
async function main() {
  const args = process.argv.slice(2);
  const dryRun = args.includes('--dry-run');

  console.log('🚀 Web Extension to iOS Wallpaper Converter\n');
  console.log(`Source: ${SOURCE_PATH}`);
  console.log(`Output: ${OUTPUT_PATH}`);
  console.log(`Mode: ${dryRun ? 'DRY RUN (preview only)' : 'CONVERSION'}\n`);

  // Check prerequisites
  if (!dryRun) {
    try {
      execSync('magick -version', { stdio: 'ignore' });
      console.log('✅ ImageMagick found\n');
    } catch (error) {
      console.error('❌ ImageMagick not found. Please install it first:');
      console.error('   brew install imagemagick');
      process.exit(1);
    }
  }

  // Parse manifest
  const { collections, wallpapers } = parseWebManifest();

  if (wallpapers.length === 0) {
    console.error('❌ No wallpapers found in manifest');
    process.exit(1);
  }

  // Create output directory
  if (!dryRun) {
    fs.mkdirSync(OUTPUT_PATH, { recursive: true });
  }

  // Generate iOS variants for each wallpaper
  console.log('\n🖼️  Generating iOS variants...\n');

  let successCount = 0;
  let errorCount = 0;

  for (const wallpaper of wallpapers) {
    try {
      generateIosVariants(wallpaper, dryRun);
      successCount++;
    } catch (error) {
      console.error(`❌ Error processing ${wallpaper.id}: ${error.message}`);
      errorCount++;
    }
  }

  // Generate metadata JSON
  const metadata = generateIosMetadata(collections, wallpapers);

  if (!dryRun) {
    const metadataDir = path.join(OUTPUT_PATH, 'metadata/v1');
    fs.mkdirSync(metadataDir, { recursive: true });
    const metadataPath = path.join(metadataDir, 'wallpapers.json');
    fs.writeFileSync(metadataPath, JSON.stringify(metadata, null, 2));
    console.log(`\n💾 Saved metadata: ${metadataPath}`);
  }

  // Summary
  console.log('\n' + '='.repeat(60));
  console.log('📊 Conversion Summary');
  console.log('='.repeat(60));
  console.log(`Collections: ${collections.length}`);
  console.log(`Wallpapers: ${wallpapers.length}`);
  console.log(`Successful: ${successCount}`);
  console.log(`Errors: ${errorCount}`);
  console.log(`Total variants: ${successCount * 5}`);

  if (dryRun) {
    console.log('\n💡 This was a dry run. Run without --dry-run to convert images.');
  } else {
    console.log(`\n✅ Conversion complete! Output: ${OUTPUT_PATH}`);
  }
}

// Run
main().catch(error => {
  console.error('❌ Fatal error:', error);
  process.exit(1);
});
