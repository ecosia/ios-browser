#!/bin/bash
#
# check_translations.sh
#
# Validates that all keys in the English Ecosia.strings file have corresponding
# translations in all supported language files (de, fr, nl, es, it).
#
# Exits with a non-zero status if any translations are missing, unless
# DRY_RUN is set to "true" (in which case it reports but does not fail).

set -euo pipefail

L10N_DIR="firefox-ios/Ecosia/L10N"
EN_FILE="${L10N_DIR}/en.lproj/Ecosia.strings"
SUPPORTED_LANGUAGES=("de" "fr" "nl" "es" "it")

DRY_RUN="${DRY_RUN:-false}"

if [[ "$DRY_RUN" == "true" ]]; then
  echo "🧪 DRY RUN MODE: Will report missing translations but will not fail the build"
fi

# Verify the English source file exists
if [[ ! -f "$EN_FILE" ]]; then
  echo "❌ Error: English source file not found at $EN_FILE"
  exit 1
fi

# Extract keys from a .strings file (UTF-8 input expected)
# Matches lines of the form: "key" = "value";
extract_keys() {
  grep -o '^"[^"]*"' "$1" | sort
}

# Extract English keys (already UTF-8)
EN_KEYS_FILE=$(mktemp)
extract_keys "$EN_FILE" > "$EN_KEYS_FILE"

EN_KEY_COUNT=$(wc -l < "$EN_KEYS_FILE" | tr -d ' ')
echo "📋 Found $EN_KEY_COUNT keys in English source file"

MISSING_FOUND=0
SUMMARY=""

for LANG in "${SUPPORTED_LANGUAGES[@]}"; do
  LANG_FILE="${L10N_DIR}/${LANG}.lproj/Ecosia.strings"

  if [[ ! -f "$LANG_FILE" ]]; then
    echo "❌ Error: Translation file not found for language '${LANG}' at ${LANG_FILE}"
    MISSING_FOUND=1
    SUMMARY="${SUMMARY}\n❌ ${LANG}: File not found"
    continue
  fi

  # Convert from UTF-16 to UTF-8 for reliable parsing
  CONVERTED_FILE=$(mktemp)
  iconv -f UTF-16 -t UTF-8 "$LANG_FILE" > "$CONVERTED_FILE" 2>/dev/null || {
    # If UTF-16 conversion fails, try reading as-is (might already be UTF-8)
    cp "$LANG_FILE" "$CONVERTED_FILE"
  }

  # Extract keys from the translated file
  LANG_KEYS_FILE=$(mktemp)
  extract_keys "$CONVERTED_FILE" > "$LANG_KEYS_FILE"

  # Find keys present in English but missing in the translation
  MISSING_KEYS=$(comm -23 "$EN_KEYS_FILE" "$LANG_KEYS_FILE")

  if [[ -n "$MISSING_KEYS" ]]; then
    MISSING_COUNT=$(echo "$MISSING_KEYS" | wc -l | tr -d ' ')
    MISSING_FOUND=1
    echo ""
    echo "❌ Language '${LANG}' is missing $MISSING_COUNT translation(s):"
    echo "$MISSING_KEYS" | while read -r key; do
      echo "   - $key"
    done
    SUMMARY="${SUMMARY}\n❌ ${LANG}: Missing $MISSING_COUNT key(s)"
  else
    echo "✅ Language '${LANG}': All keys translated"
    SUMMARY="${SUMMARY}\n✅ ${LANG}: Complete"
  fi

  rm -f "$CONVERTED_FILE" "$LANG_KEYS_FILE"
done

rm -f "$EN_KEYS_FILE"

echo ""
echo "═══════════════════════════════════════"
echo "📊 Translation Check Summary:"
echo -e "$SUMMARY"
echo "═══════════════════════════════════════"

if [[ "$MISSING_FOUND" -eq 1 ]]; then
  if [[ "$DRY_RUN" == "true" ]]; then
    echo ""
    echo "🧪 DRY RUN: Missing translations detected but not failing the build"
    exit 0
  else
    echo ""
    echo "❌ Translation check FAILED: Some translations are missing."
    echo "Please add the missing keys to the corresponding .strings files."
    exit 1
  fi
else
  echo ""
  echo "✅ All translations are complete!"
  exit 0
fi
