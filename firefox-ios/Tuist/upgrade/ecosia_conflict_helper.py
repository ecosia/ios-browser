#!/usr/bin/env python3
"""
Ecosia Conflict Helper

Detects and helps resolve merge conflicts in files with Ecosia customizations.
During a Firefox upgrade rebase, this tool:
1. Identifies conflicts involving Ecosia customizations
2. Analyzes the conflict context
3. Suggests resolution strategies
4. Optionally applies automatic resolutions

Usage:
    # Analyze a file with conflicts
    python3 firefox-ios/Tuist/upgrade/ecosia-conflict-helper --file firefox-ios/Client/Application/AppDelegate.swift
    
    # Analyze all conflicted files
    python3 firefox-ios/Tuist/upgrade/ecosia-conflict-helper --all
    
    # Dry-run mode (no modifications)
    python3 firefox-ios/Tuist/upgrade/ecosia-conflict-helper --all --dry-run
    
    # Use custom catalog
    python3 firefox-ios/Tuist/upgrade/ecosia-conflict-helper --all --catalog my-catalog.json
"""

import re
import json
import subprocess
import argparse
from pathlib import Path
from typing import List, Dict, Tuple, Optional
from dataclasses import dataclass
from enum import Enum


class ConflictType(Enum):
    """Types of conflicts"""
    REMOVAL_REINTRODUCED = "removal_reintroduced"  # Firefox re-added code Ecosia removed
    SUBSTITUTION_CHANGED = "substitution_changed"  # Firefox changed code Ecosia replaced
    ADDITION_MOVED = "addition_moved"  # Context around Ecosia addition changed
    UNKNOWN = "unknown"


class ResolutionStrategy(Enum):
    """Resolution strategies"""
    KEEP_ECOSIA = "keep_ecosia"  # Keep Ecosia customization as-is
    UPDATE_COMMENT = "update_comment"  # Update commented Firefox code
    MERGE_BOTH = "merge_both"  # Merge Firefox and Ecosia changes
    MANUAL = "manual"  # Requires manual resolution


@dataclass
class ConflictRegion:
    """Represents a conflict region in a file"""
    file_path: str
    start_line: int
    ecosia_version: str
    firefox_version: str
    firefox_branch: str
    ecosia_customization: Optional[Dict] = None
    conflict_type: ConflictType = ConflictType.UNKNOWN
    resolution_strategy: ResolutionStrategy = ResolutionStrategy.MANUAL
    suggested_resolution: Optional[str] = None


def load_catalog(catalog_path: str) -> Dict:
    """Load the Ecosia customizations catalog."""
    try:
        with open(catalog_path, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"⚠️  Warning: Catalog not found: {catalog_path}")
        print("   Run: python3 firefox-ios/Tuist/upgrade/ecosia-customizations-catalog.py --scan firefox-ios/")
        return {'customizations': []}
    except Exception as e:
        print(f"❌ Error loading catalog: {e}")
        return {'customizations': []}


def find_conflicted_files() -> List[str]:
    """Find all files with unresolved merge conflicts."""
    try:
        result = subprocess.run(
            ['git', 'diff', '--name-only', '--diff-filter=U'],
            capture_output=True,
            text=True,
            check=True
        )
        return [f.strip() for f in result.stdout.strip().split('\n') if f.strip()]
    except subprocess.CalledProcessError:
        print("❌ Error: Not in a git repository or no conflicts found")
        return []
    except FileNotFoundError:
        print("❌ Error: git command not found")
        return []


def extract_conflicts(file_path: str) -> List[ConflictRegion]:
    """
    Extract conflict regions from a file.
    
    Parses conflict markers:
        <<<<<<< HEAD
        ... Ecosia version ...
        =======
        ... Firefox version ...
        >>>>>>> firefox-v141.0
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"⚠️  Warning: Could not read {file_path}: {e}")
        return []
    
    conflicts = []
    
    # Regex to find conflict regions
    pattern = r'<<<<<<< HEAD\n(.*?)\n=======\n(.*?)\n>>>>>>> (.+?)\n'
    
    # Track line numbers
    lines_before = 0
    for match in re.finditer(pattern, content, re.DOTALL):
        ecosia_version = match.group(1)
        firefox_version = match.group(2)
        firefox_branch = match.group(3)
        
        # Calculate line number
        lines_before = content[:match.start()].count('\n')
        
        conflicts.append(ConflictRegion(
            file_path=file_path,
            start_line=lines_before + 1,
            ecosia_version=ecosia_version,
            firefox_version=firefox_version,
            firefox_branch=firefox_branch,
        ))
    
    return conflicts


def find_customization_in_conflict(
    conflict: ConflictRegion,
    catalog: Dict
) -> Optional[Dict]:
    """
    Find if this conflict involves an Ecosia customization.
    
    Checks if the conflict contains:
    - Ecosia comment markers (// Ecosia: or /* Ecosia:)
    - Code from known Ecosia customizations
    """
    # Get customizations for this file
    file_customizations = [
        c for c in catalog['customizations']
        if c['file'] == conflict.file_path
    ]
    
    if not file_customizations:
        return None
    
    # Check if Ecosia version contains any Ecosia markers
    for custom in file_customizations:
        comment = custom['comment']
        
        # Simple heuristic: Check if comment text appears in conflict
        if comment in conflict.ecosia_version or comment in conflict.firefox_version:
            return custom
        
        # Check if any Ecosia code appears in conflict
        for line in custom['ecosia_code']:
            if line.strip() and line.strip() in conflict.ecosia_version:
                return custom
    
    return None


def analyze_conflict(conflict: ConflictRegion, catalog: Dict) -> ConflictRegion:
    """
    Analyze a conflict and determine type and resolution strategy.
    """
    # Find associated Ecosia customization
    customization = find_customization_in_conflict(conflict, catalog)
    
    if not customization:
        # No Ecosia customization involved - standard conflict
        conflict.conflict_type = ConflictType.UNKNOWN
        conflict.resolution_strategy = ResolutionStrategy.MANUAL
        return conflict
    
    conflict.ecosia_customization = customization
    
    # Determine conflict type based on customization type
    custom_type = customization['type']
    
    if custom_type == 'removal':
        # Firefox re-introduced code that Ecosia commented out
        conflict.conflict_type = ConflictType.REMOVAL_REINTRODUCED
        conflict.resolution_strategy = ResolutionStrategy.KEEP_ECOSIA
        conflict.suggested_resolution = generate_removal_resolution(conflict, customization)
    
    elif custom_type == 'substitution':
        # Firefox changed code that Ecosia replaced
        conflict.conflict_type = ConflictType.SUBSTITUTION_CHANGED
        conflict.resolution_strategy = ResolutionStrategy.UPDATE_COMMENT
        conflict.suggested_resolution = generate_substitution_resolution(conflict, customization)
    
    elif custom_type == 'addition':
        # Context around Ecosia addition changed
        conflict.conflict_type = ConflictType.ADDITION_MOVED
        conflict.resolution_strategy = ResolutionStrategy.MERGE_BOTH
        conflict.suggested_resolution = generate_addition_resolution(conflict, customization)
    
    return conflict


def generate_removal_resolution(conflict: ConflictRegion, customization: Dict) -> str:
    """
    Generate resolution for REMOVAL conflicts.
    
    Strategy: Keep the Firefox code commented out, update it to latest version.
    """
    firefox_new = conflict.firefox_version.strip()
    comment = customization['comment']
    
    return f"""/* Ecosia: {comment}
{firefox_new}
 */"""


def generate_substitution_resolution(conflict: ConflictRegion, customization: Dict) -> str:
    """
    Generate resolution for SUBSTITUTION conflicts.
    
    Strategy: Update commented Firefox code, keep Ecosia replacement.
    """
    firefox_new = conflict.firefox_version.strip()
    comment = customization['comment']
    ecosia_code = '\n'.join(customization['ecosia_code'])
    
    # Check if Firefox code needs updating
    firefox_lines = firefox_new.split('\n')
    commented_firefox = '\n'.join(f"// {line}" if line.strip() else '//' for line in firefox_lines)
    
    return f"""// Ecosia: {comment}
{commented_firefox}
{ecosia_code}"""


def generate_addition_resolution(conflict: ConflictRegion, customization: Dict) -> str:
    """
    Generate resolution for ADDITION conflicts.
    
    Strategy: Keep both Firefox changes and Ecosia addition.
    """
    firefox_new = conflict.firefox_version.strip()
    comment = customization['comment']
    ecosia_code = '\n'.join(customization['ecosia_code'])
    
    return f"""{firefox_new}

// Ecosia: {comment}
{ecosia_code}"""


def print_conflict_analysis(conflict: ConflictRegion):
    """Pretty-print conflict analysis."""
    print("="*70)
    print(f"📍 {conflict.file_path}:{conflict.start_line}")
    print("="*70)
    
    if conflict.ecosia_customization:
        custom = conflict.ecosia_customization
        print(f"🔍 Ecosia Customization: {custom['comment']}")
        print(f"   Type: {custom['type'].upper()}")
        print(f"   Original line: {custom['line']}")
    else:
        print("ℹ️  No Ecosia customization detected")
    
    print(f"\n📊 Analysis:")
    print(f"   Conflict Type: {conflict.conflict_type.value}")
    print(f"   Resolution Strategy: {conflict.resolution_strategy.value}")
    
    print(f"\n📝 Current Conflict:")
    print("┌─ Ecosia Version (HEAD) ─────────────────────────────────┐")
    print_indented(conflict.ecosia_version, "│ ", " │")
    print("├─ Firefox Version ({}) ─────────────────┤".format(conflict.firefox_branch))
    print_indented(conflict.firefox_version, "│ ", " │")
    print("└──────────────────────────────────────────────────────────┘")
    
    if conflict.suggested_resolution:
        print(f"\n✅ Suggested Resolution:")
        print("┌─ Apply this ─────────────────────────────────────────────┐")
        print_indented(conflict.suggested_resolution, "│ ", " │")
        print("└──────────────────────────────────────────────────────────┘")
    else:
        print("\n⚠️  Manual resolution required")
        print_resolution_guidelines(conflict)
    
    print()


def print_indented(text: str, prefix: str, suffix: str):
    """Print text with prefix/suffix on each line."""
    for line in text.split('\n'):
        print(f"{prefix}{line:<56}{suffix}")


def print_resolution_guidelines(conflict: ConflictRegion):
    """Print guidelines for manual resolution."""
    if not conflict.ecosia_customization:
        print("""
GUIDELINES:
  1. Review both versions carefully
  2. Understand what changed in Firefox
  3. Preserve Ecosia's intent
  4. Test after resolution
""")
        return
    
    custom_type = conflict.ecosia_customization['type']
    
    if custom_type == 'removal':
        print("""
REMOVAL GUIDELINES:
  1. Firefox re-introduced code that Ecosia disabled
  2. Keep the code commented out with /* Ecosia: ... */
  3. Update the commented code to Firefox's new version
  4. Ensure Ecosia's reason for removal still applies
""")
    
    elif custom_type == 'substitution':
        print("""
SUBSTITUTION GUIDELINES:
  1. Firefox changed code that Ecosia replaced
  2. Update the commented Firefox code to new version
  3. Evaluate if Ecosia's replacement needs updating
  4. Test that Ecosia code still works with Firefox changes
""")
    
    elif custom_type == 'addition':
        print("""
ADDITION GUIDELINES:
  1. Context around Ecosia's addition changed
  2. Keep both Firefox's changes and Ecosia's addition
  3. Ensure no logical conflicts between them
  4. Place Ecosia code in appropriate location
""")


def apply_resolution(conflict: ConflictRegion, dry_run: bool = False) -> bool:
    """
    Apply the suggested resolution to the file.
    
    Returns True if resolution was applied, False otherwise.
    """
    if not conflict.suggested_resolution:
        return False
    
    if dry_run:
        print(f"   [DRY-RUN] Would apply resolution to {conflict.file_path}:{conflict.start_line}")
        return False
    
    # Read file
    try:
        with open(conflict.file_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"❌ Error reading file: {e}")
        return False
    
    # Build conflict pattern to replace
    conflict_pattern = f"""<<<<<<< HEAD
{conflict.ecosia_version}
=======
{conflict.firefox_version}
>>>>>>> {conflict.firefox_branch}
"""
    
    # Replace with resolution
    if conflict_pattern in content:
        new_content = content.replace(conflict_pattern, conflict.suggested_resolution)
        
        # Write back
        try:
            with open(conflict.file_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"   ✅ Applied resolution to {conflict.file_path}:{conflict.start_line}")
            return True
        except Exception as e:
            print(f"❌ Error writing file: {e}")
            return False
    else:
        print(f"⚠️  Could not find exact conflict pattern (file may have changed)")
        return False


def main():
    parser = argparse.ArgumentParser(
        description='Ecosia Conflict Helper - Analyze and resolve conflicts with Ecosia customizations',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Analyze a specific file
  python3 firefox-ios/Tuist/upgrade/ecosia-conflict-helper --file firefox-ios/Client/Application/AppDelegate.swift
  
  # Analyze all conflicted files
  python3 firefox-ios/Tuist/upgrade/ecosia-conflict-helper --all
  
  # Dry-run (no modifications)
  python3 firefox-ios/Tuist/upgrade/ecosia-conflict-helper --all --dry-run
  
  # Apply suggested resolutions automatically
  python3 firefox-ios/Tuist/upgrade/ecosia-conflict-helper --all --auto-resolve
  
  # Use custom catalog
  python3 firefox-ios/Tuist/upgrade/ecosia-conflict-helper --all --catalog my-catalog.json
        """
    )
    
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        '--file',
        help='Specific file to analyze'
    )
    group.add_argument(
        '--all',
        action='store_true',
        help='Analyze all files with conflicts'
    )
    
    parser.add_argument(
        '--catalog',
        default='ecosia-customizations.json',
        help='Path to customizations catalog (default: ecosia-customizations.json)'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Analyze conflicts without applying resolutions'
    )
    parser.add_argument(
        '--auto-resolve',
        action='store_true',
        help='Automatically apply suggested resolutions (USE WITH CAUTION)'
    )
    parser.add_argument(
        '--summary-only',
        action='store_true',
        help='Only print summary, skip detailed analysis'
    )
    
    args = parser.parse_args()
    
    # Load catalog
    catalog = load_catalog(args.catalog)
    
    # Get files to analyze
    if args.file:
        files = [args.file]
    else:
        files = find_conflicted_files()
        if not files:
            print("✅ No conflicted files found")
            print("   Either:")
            print("   - There are no merge conflicts")
            print("   - You're not in a rebase/merge")
            print("   - Run 'git status' to check")
            return 0
    
    print(f"🔍 Analyzing {len(files)} file(s) with conflicts...\n")
    
    # Analyze all conflicts
    all_conflicts = []
    for file_path in files:
        conflicts = extract_conflicts(file_path)
        for conflict in conflicts:
            analyzed = analyze_conflict(conflict, catalog)
            all_conflicts.append(analyzed)
    
    if not all_conflicts:
        print("✅ No conflicts found in specified files")
        return 0
    
    # Print summary
    ecosia_conflicts = [c for c in all_conflicts if c.ecosia_customization]
    standard_conflicts = [c for c in all_conflicts if not c.ecosia_customization]
    
    print("="*70)
    print("📊 CONFLICT SUMMARY")
    print("="*70)
    print(f"Total Conflicts: {len(all_conflicts)}")
    print(f"  • Ecosia Customization Conflicts: {len(ecosia_conflicts)}")
    print(f"  • Standard Conflicts: {len(standard_conflicts)}")
    
    if ecosia_conflicts:
        print(f"\nEcosia Conflict Breakdown:")
        removal_count = len([c for c in ecosia_conflicts if c.conflict_type == ConflictType.REMOVAL_REINTRODUCED])
        subst_count = len([c for c in ecosia_conflicts if c.conflict_type == ConflictType.SUBSTITUTION_CHANGED])
        addition_count = len([c for c in ecosia_conflicts if c.conflict_type == ConflictType.ADDITION_MOVED])
        
        print(f"  • Removal Reintroduced: {removal_count}")
        print(f"  • Substitution Changed: {subst_count}")
        print(f"  • Addition Context Changed: {addition_count}")
        
        auto_resolvable = len([c for c in ecosia_conflicts if c.suggested_resolution])
        print(f"\nAuto-Resolvable: {auto_resolvable}/{len(ecosia_conflicts)}")
    
    print("="*70)
    print()
    
    if args.summary_only:
        return 0
    
    # Print detailed analysis for each conflict
    for conflict in all_conflicts:
        print_conflict_analysis(conflict)
    
    # Apply resolutions if requested
    if args.auto_resolve and not args.dry_run:
        print("\n" + "="*70)
        print("🔧 APPLYING RESOLUTIONS")
        print("="*70)
        
        applied_count = 0
        for conflict in ecosia_conflicts:
            if apply_resolution(conflict, dry_run=False):
                applied_count += 1
        
        print(f"\n✅ Applied {applied_count} automatic resolutions")
        print(f"⚠️  {len(all_conflicts) - applied_count} conflicts require manual resolution")
        print("\nNext steps:")
        print("  1. Review the applied changes: git diff")
        print("  2. Resolve remaining conflicts manually")
        print("  3. Stage resolved files: git add <files>")
        print("  4. Continue rebase: git rebase --continue")
    elif args.dry_run:
        print("💡 Tip: Run without --dry-run to apply suggested resolutions")
        print("   Or use --auto-resolve for fully automatic application")
    
    return 0


if __name__ == '__main__':
    import sys
    sys.exit(main())
