#!/usr/bin/env python3
"""
Apply Ecosia Customizations

Applies Ecosia customizations from the catalog to a clean Firefox codebase.
This script reads ecosia-customizations.json and applies each change:
- Removal: Comments out Firefox code with "// Ecosia:" prefix
- Substitution: Comments out Firefox code and adds Ecosia replacement
- Addition: Inserts new Ecosia code at the appropriate location

Usage:
    # Apply all customizations
    python3 apply-ecosia-customizations.py \\
      --catalog firefox-ios/Tuist/upgrade/ecosia-customizations.json \\
      --target firefox-ios/

    # Dry-run (preview only)
    python3 apply-ecosia-customizations.py \\
      --catalog firefox-ios/Tuist/upgrade/ecosia-customizations.json \\
      --target firefox-ios/ \\
      --dry-run

    # Apply to specific file
    python3 apply-ecosia-customizations.py \\
      --catalog firefox-ios/Tuist/upgrade/ecosia-customizations.json \\
      --file firefox-ios/Client/Application/AppDelegate.swift

    # Verbose output
    python3 apply-ecosia-customizations.py \\
      --catalog firefox-ios/Tuist/upgrade/ecosia-customizations.json \\
      --target firefox-ios/ \\
      --verbose
"""

import re
import json
import argparse
from pathlib import Path
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass
from difflib import SequenceMatcher


@dataclass
class Customization:
    """Represents a single Ecosia customization"""
    file: str
    line: int
    type: str  # "removal", "substitution", "addition"
    comment: str
    firefox_code: List[str]
    ecosia_code: List[str]
    context_before: List[str]
    context_after: List[str]


@dataclass
class ApplyResult:
    """Result of applying a customization"""
    success: bool
    file: str
    line: int
    type: str
    message: str


def load_catalog(catalog_path: str) -> Dict:
    """Load the Ecosia customizations catalog."""
    try:
        with open(catalog_path, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"❌ Error: Catalog not found: {catalog_path}")
        exit(1)
    except Exception as e:
        print(f"❌ Error loading catalog: {e}")
        exit(1)


def normalize_line(line: str) -> str:
    """Normalize a line for comparison (strip whitespace, handle common variations)."""
    return line.strip()


def find_context_match(lines: List[str], context_before: List[str], context_after: List[str], 
                       original_line: int, tolerance: int = 50) -> Optional[int]:
    """
    Find the best match for context in the file.
    Returns the line number where the change should be applied, or None if not found.
    Uses fuzzy matching to handle minor variations.
    
    Note: Primarily uses context_before for matching since context_after may contain
    Ecosia customizations rather than original Firefox code.
    """
    # Search within +/- tolerance lines of the original position
    search_start = max(0, original_line - tolerance)
    search_end = min(len(lines), original_line + tolerance)
    
    best_match_score = 0.0
    best_match_line = None
    
    for i in range(search_start, search_end):
        # Check if context_before matches
        before_start = i - len(context_before)
        if before_start < 0:
            continue
            
        before_lines = lines[before_start:i]
        before_score = compare_context(before_lines, context_before)
        
        # Use before_score as primary match criteria
        # (context_after may contain Ecosia code, not Firefox code)
        if before_score > best_match_score:
            best_match_score = before_score
            best_match_line = i
    
    # Require at least 80% match for context_before
    if best_match_score >= 0.8:
        return best_match_line
    
    return None


def compare_context(actual: List[str], expected: List[str]) -> float:
    """Compare two contexts and return similarity score (0.0 to 1.0)."""
    if not expected:
        return 1.0
    
    if len(actual) != len(expected):
        return 0.0
    
    matches = 0
    for a, e in zip(actual, expected):
        # Normalize both lines
        a_norm = normalize_line(a)
        e_norm = normalize_line(e)
        
        # Use SequenceMatcher for fuzzy comparison
        similarity = SequenceMatcher(None, a_norm, e_norm).ratio()
        if similarity >= 0.9:  # 90% similar
            matches += 1
    
    return matches / len(expected)


def apply_removal(lines: List[str], customization: Customization, match_line: int, 
                  verbose: bool = False) -> Tuple[List[str], str]:
    """
    Apply a removal customization.
    Comments out Firefox code instead of deleting it.
    """
    firefox_lines = customization.firefox_code
    
    # Find the exact lines to comment out
    start_line = match_line
    end_line = start_line + len(firefox_lines)
    
    if end_line > len(lines):
        return lines, "Error: Not enough lines to comment out"
    
    # Verify the lines match what we expect
    actual_lines = lines[start_line:end_line]
    if not verify_lines_match(actual_lines, firefox_lines):
        return lines, "Error: Lines don't match expected Firefox code"
    
    # Comment out the lines
    new_lines = lines[:start_line]
    
    # Add comment header
    indent = get_indent(lines[start_line])
    new_lines.append(f"{indent}// Ecosia: {customization.comment}\n")
    
    # Comment out each Firefox line
    for line in actual_lines:
        if line.strip():
            new_lines.append(f"{indent}// Firefox: {line.lstrip()}")
        else:
            new_lines.append(line)
    
    new_lines.extend(lines[end_line:])
    
    if verbose:
        msg = f"Commented out {len(firefox_lines)} line(s)"
    else:
        msg = "Success"
    
    return new_lines, msg


def apply_substitution(lines: List[str], customization: Customization, match_line: int, 
                       verbose: bool = False) -> Tuple[List[str], str]:
    """
    Apply a substitution customization.
    Comments out Firefox code and adds Ecosia replacement.
    """
    firefox_lines = customization.firefox_code
    ecosia_lines = customization.ecosia_code
    
    # Find the exact lines to replace
    start_line = match_line
    end_line = start_line + len(firefox_lines)
    
    if end_line > len(lines):
        return lines, "Error: Not enough lines to replace"
    
    # Verify the lines match what we expect
    actual_lines = lines[start_line:end_line]
    if not verify_lines_match(actual_lines, firefox_lines, fuzzy=True):
        return lines, "Error: Lines don't match expected Firefox code"
    
    # Get indentation from the original line
    indent = get_indent(lines[start_line]) if start_line < len(lines) else ""
    
    # Build replacement
    new_lines = lines[:start_line]
    
    # Add comment header
    new_lines.append(f"{indent}// Ecosia: {customization.comment}\n")
    
    # Comment out Firefox lines
    for line in actual_lines:
        if line.strip():
            new_lines.append(f"{indent}// Firefox: {line.lstrip()}")
        else:
            new_lines.append(line)
    
    # Add Ecosia replacement
    for line in ecosia_lines:
        # Preserve original indentation if the Ecosia line has its own, otherwise use indent
        if line.startswith(' ') or line.startswith('\t'):
            new_lines.append(line if line.endswith('\n') else line + '\n')
        else:
            new_lines.append(f"{indent}{line}\n" if not line.endswith('\n') else f"{indent}{line}")
    
    new_lines.extend(lines[end_line:])
    
    if verbose:
        msg = f"Replaced {len(firefox_lines)} line(s) with {len(ecosia_lines)} line(s)"
    else:
        msg = "Success"
    
    return new_lines, msg


def apply_addition(lines: List[str], customization: Customization, match_line: int, 
                   verbose: bool = False) -> Tuple[List[str], str]:
    """
    Apply an addition customization.
    Inserts new Ecosia code at the specified location.
    """
    ecosia_lines = customization.ecosia_code
    
    # Get indentation from surrounding context
    indent = ""
    if match_line > 0 and match_line < len(lines):
        indent = get_indent(lines[match_line])
    elif match_line > 0:
        indent = get_indent(lines[match_line - 1])
    
    # Build new content
    new_lines = lines[:match_line]
    
    # Add comment header
    new_lines.append(f"{indent}// Ecosia: {customization.comment}\n")
    
    # Add Ecosia code
    for line in ecosia_lines:
        # Preserve original indentation if the Ecosia line has its own
        if line.startswith(' ') or line.startswith('\t'):
            new_lines.append(line if line.endswith('\n') else line + '\n')
        else:
            new_lines.append(f"{indent}{line}\n" if not line.endswith('\n') else f"{indent}{line}")
    
    new_lines.extend(lines[match_line:])
    
    if verbose:
        msg = f"Added {len(ecosia_lines)} line(s)"
    else:
        msg = "Success"
    
    return new_lines, msg


def verify_lines_match(actual: List[str], expected: List[str], fuzzy: bool = False) -> bool:
    """Verify that actual lines match expected lines."""
    if len(actual) != len(expected):
        return False
    
    for a, e in zip(actual, expected):
        a_norm = normalize_line(a)
        e_norm = normalize_line(e)
        
        if fuzzy:
            # Allow 90% similarity
            similarity = SequenceMatcher(None, a_norm, e_norm).ratio()
            if similarity < 0.9:
                return False
        else:
            if a_norm != e_norm:
                return False
    
    return True


def get_indent(line: str) -> str:
    """Extract indentation from a line."""
    match = re.match(r'^(\s*)', line)
    return match.group(1) if match else ""


def apply_customization(file_path: str, customization: Customization, 
                        dry_run: bool = False, verbose: bool = False) -> ApplyResult:
    """Apply a single customization to a file."""
    try:
        # Read file
        with open(file_path, 'r') as f:
            lines = f.readlines()
        
        # Find where to apply the change using context matching
        match_line = find_context_match(
            lines,
            customization.context_before,
            customization.context_after,
            customization.line - 1  # Convert to 0-indexed
        )
        
        if match_line is None:
            return ApplyResult(
                success=False,
                file=customization.file,
                line=customization.line,
                type=customization.type,
                message=f"Context not found (searched around line {customization.line})"
            )
        
        # Apply the appropriate transformation
        if customization.type == "removal":
            new_lines, msg = apply_removal(lines, customization, match_line, verbose)
        elif customization.type == "substitution":
            new_lines, msg = apply_substitution(lines, customization, match_line, verbose)
        elif customization.type == "addition":
            new_lines, msg = apply_addition(lines, customization, match_line, verbose)
        else:
            return ApplyResult(
                success=False,
                file=customization.file,
                line=customization.line,
                type=customization.type,
                message=f"Unknown customization type: {customization.type}"
            )
        
        if "Error:" in msg:
            return ApplyResult(
                success=False,
                file=customization.file,
                line=customization.line,
                type=customization.type,
                message=msg
            )
        
        # Write back (unless dry-run)
        if not dry_run:
            with open(file_path, 'w') as f:
                f.writelines(new_lines)
        
        return ApplyResult(
            success=True,
            file=customization.file,
            line=match_line + 1,  # Convert back to 1-indexed
            type=customization.type,
            message=msg
        )
    
    except Exception as e:
        return ApplyResult(
            success=False,
            file=customization.file,
            line=customization.line,
            type=customization.type,
            message=f"Exception: {str(e)}"
        )


def main():
    parser = argparse.ArgumentParser(
        description='Apply Ecosia customizations from catalog to Firefox codebase',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    parser.add_argument('--catalog', required=True, help='Path to ecosia-customizations.json')
    parser.add_argument('--target', help='Target directory to apply customizations (e.g., firefox-ios/)')
    parser.add_argument('--file', help='Apply to specific file only')
    parser.add_argument('--dry-run', action='store_true', help='Preview changes without modifying files')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')
    
    args = parser.parse_args()
    
    if not args.target and not args.file:
        print("❌ Error: Either --target or --file must be specified")
        exit(1)
    
    # Load catalog
    print(f"📖 Loading catalog: {args.catalog}")
    catalog = load_catalog(args.catalog)
    
    customizations_data = catalog.get('customizations', [])
    print(f"   Found {len(customizations_data)} customizations")
    
    if args.dry_run:
        print("🔍 DRY-RUN MODE: No files will be modified\n")
    
    # Parse customizations
    customizations = []
    for c in customizations_data:
        customization = Customization(
            file=c['file'],
            line=c['line'],
            type=c['type'],
            comment=c['comment'],
            firefox_code=c['firefox_code'],
            ecosia_code=c['ecosia_code'],
            context_before=c['context_before'],
            context_after=c['context_after']
        )
        
        # Filter by file if specified
        if args.file:
            if customization.file != args.file and not customization.file.endswith('/' + args.file):
                continue
        # Filter by target directory if specified
        elif args.target:
            if not customization.file.startswith(args.target):
                continue
        
        customizations.append(customization)
    
    print(f"📋 Applying {len(customizations)} customizations\n")
    
    # Group by file
    files_map: Dict[str, List[Customization]] = {}
    for c in customizations:
        if c.file not in files_map:
            files_map[c.file] = []
        files_map[c.file].append(c)
    
    # Apply customizations file by file (in reverse line order to avoid shifts)
    results = []
    for file_path, file_customizations in sorted(files_map.items()):
        # Sort by line number (descending) to apply from bottom to top
        file_customizations.sort(key=lambda c: c.line, reverse=True)
        
        print(f"📝 {file_path} ({len(file_customizations)} customization(s))")
        
        for customization in file_customizations:
            result = apply_customization(file_path, customization, args.dry_run, args.verbose)
            results.append(result)
            
            if result.success:
                icon = "✅"
                if args.verbose:
                    print(f"   {icon} Line {result.line}: {result.type} - {result.message}")
                else:
                    print(f"   {icon} Line {result.line}: {result.type}")
            else:
                icon = "❌"
                print(f"   {icon} Line {result.line}: {result.type} - {result.message}")
    
    # Print summary
    print("\n" + "=" * 60)
    print("📊 SUMMARY")
    print("=" * 60)
    
    successful = [r for r in results if r.success]
    failed = [r for r in results if not r.success]
    
    print(f"✅ Successful: {len(successful)}")
    print(f"❌ Failed:     {len(failed)}")
    print(f"📝 Total:      {len(results)}")
    
    # Breakdown by type
    removals = [r for r in successful if r.type == "removal"]
    substitutions = [r for r in successful if r.type == "substitution"]
    additions = [r for r in successful if r.type == "addition"]
    
    print(f"\nBy type:")
    print(f"  • Removals:      {len(removals)}")
    print(f"  • Substitutions: {len(substitutions)}")
    print(f"  • Additions:     {len(additions)}")
    
    if failed:
        print(f"\n⚠️  {len(failed)} customization(s) could not be applied:")
        for r in failed[:10]:  # Show first 10
            print(f"  • {r.file}:{r.line} - {r.message}")
        if len(failed) > 10:
            print(f"  ... and {len(failed) - 10} more")
    
    print("=" * 60)
    
    if args.dry_run:
        print("\n🔍 Dry-run complete. No files were modified.")
    else:
        print(f"\n✨ Applied {len(successful)} customizations!")
    
    # Exit with error if any failed
    if failed:
        exit(1)


if __name__ == '__main__':
    main()
