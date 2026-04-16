#!/usr/bin/env python3
"""
Replace Firefox / Mozilla brand names with Ecosia in iOS localization (.strings) files.

Targets the two framework directories that carry upstream Mozilla strings:
  - firefox-ios/Shared    (base strings shared across all targets, ~100 locales)
  - firefox-ios/WidgetKit (widget-extension strings, ~100 locales)

Run after every upstream merge that brings in new or updated locale files:

    python3 ecosify-strings.py firefox-ios          # process entire tree
    python3 ecosify-strings.py firefox-ios/Shared   # Shared only
    python3 ecosify-strings.py firefox-ios/WidgetKit  # WidgetKit only
"""
import os
import glob
import re

# ---------------------------------------------------------------------------
# ASCII / Latin-script patterns
# ---------------------------------------------------------------------------
# Consolidated pattern for Firefox and its common grammatical declensions
# found in European translations.  The negative lookahead (?!\.[a-z]) prevents
# replacing "firefox.com" or "mozilla.org" style URLs that appear in some
# FxA / Sync instruction strings.
_LATIN_PATTERN = re.compile(
    r'(?i)(?:firefoksa|firefoxen|firefoxu|firefoxe|firefoxban|firefoksie|firefox)'
    r'(?!\.[a-z])'
)
_MOZILLA_PATTERN = re.compile(r'(?i)mozilla(?!\.[a-z])')

# ---------------------------------------------------------------------------
# Non-Latin script Firefox transliterations / translations
# ---------------------------------------------------------------------------
# Each entry is (old_string, new_string).  Longer / more-specific forms are
# listed before shorter base forms so that inflected variants are caught first.
_NON_LATIN_REPLACEMENTS = [
    # Farsi / Persian — فایرفاکس
    ('فایرفاکس', 'Ecosia'),

    # Malayalam — ഫയർഫോക്സ്
    # Locative ("-ൽ" = "in") and instrumental must precede the base form.
    ('ഫയർഫോക്സിൽ',        'Ecosia-ൽ'),
    ('ഫയർഫോക്സുപയോഗിച്ച്', 'Ecosia ഉപയോഗിച്ച്'),
    ('ഫയർഫോക്സ്',          'Ecosia'),
    ('ഫയര്‍ഫോക്സ്',         'Ecosia'),   # ZWJ variant

    # Kannada — ಫೈರ್ಫಾಕ್ಸ್
    # Locative ("-ನಲ್ಲಿ" = "in") before base form.
    ('ಫೈರ್ಫಾಕ್ಸ್ನಲ್ಲಿ', 'Ecosia ನಲ್ಲಿ'),
    ('ಫೈರ್ಫಾಕ್ಸ್',      'Ecosia'),

    # Burmese — မီးမြေခွေး (literal: "fire-earth-dog")
    ('မီးမြေခွေး', 'Ecosia'),

    # Odia — ଫାୟାରଫକ୍ସ
    ('ଫାୟାରଫକ୍ସ', 'Ecosia'),

    # Sinhala — ෆයර්ෆොක්ස්
    ('ෆයර්ෆොක්ස්', 'Ecosia'),

    # Tamil — பயர்பாஃசு / பயர்பாக்சு / பயர்பாக்ஸ்
    # Locative ("-இல்" = "in") and dative ("-க்கு" = "to") before base forms.
    ('பயர்பாக்சில்',   'Ecosia-இல்'),
    ('பயர்பாக்சுக்கு', 'Ecosia-க்கு'),
    ('பயர்பாஃசு',      'Ecosia'),
    ('பயர்பாக்சு',     'Ecosia'),
    ('பயர்பாக்ஸ்',     'Ecosia'),

    # Telugu — ఫైర్ఫాక్స్
    ('ఫైర్ఫాక్స్', 'Ecosia'),

    # Gujarati — ફાયરફોક્સ
    ('ફાયરફોક્સ', 'Ecosia'),

    # Tamazight (Tifinagh script) — ⴼⴰⵢⵔⴼⵓⴽⵙ
    ('ⴼⴰⵢⵔⴼⵓⴽⵙ', 'Ecosia'),
]


def _ecosify_value(value: str) -> str:
    """Replace all Firefox / Mozilla brand occurrences inside a string value."""
    value = _LATIN_PATTERN.sub('Ecosia', value)
    value = _MOZILLA_PATTERN.sub('Ecosia', value)
    for old, new in _NON_LATIN_REPLACEMENTS:
        value = value.replace(old, new)
    return value


def ecosify_translations(file_path: str) -> None:
    print("Replacing strings in {}".format(file_path))

    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except Exception as exc:
        print('Cannot open {}: {}'.format(file_path, exc))
        return

    newlines = []
    for line in lines:
        # Split on the first '=' only so that '=' inside values is safe.
        parts = line.split('=', 1)
        if len(parts) > 1:
            newlines.append(parts[0] + '=' + _ecosify_value(parts[1]))
        elif line.strip().endswith(';'):
            # Multi-line values: the continuation lines carry no '=' but do
            # end with ';'.  Apply brand replacements to the whole line.
            newlines.append(_ecosify_value(line))
        else:
            newlines.append(line)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(newlines)


def ecosify_dir(dir_path: str) -> None:
    for filename in glob.glob(dir_path + '/**/*.strings', recursive=True):
        if not filename.endswith('.strings'):
            continue
        if 'Ecosia' in filename:
            print("Skipping Ecosia-owned file: {}".format(filename))
            continue
        ecosify_translations(filename)


def _valid_directory(arg, parser):
    if os.path.isdir(arg):
        return arg
    parser.error("Directory does not exist: {}".format(arg))


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description=(
            "Replace Firefox and Mozilla brand names with Ecosia in iOS "
            "localization (.strings) files.  Covers firefox-ios/Shared and "
            "firefox-ios/WidgetKit when called with the firefox-ios root."
        ),
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        'ios_source',
        type=lambda arg: _valid_directory(arg, parser),
        help="The ios project's source folder (e.g. firefox-ios)",
    )
    args = parser.parse_args()
    ecosify_dir(args.ios_source)
