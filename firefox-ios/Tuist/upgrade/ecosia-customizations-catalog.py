#!/usr/bin/env python3
"""
Ecosia Customization Cataloging Tool

Scans the codebase for Ecosia-specific customizations marked with:
- `// Ecosia:` for additions and substitutions
- `/* Ecosia: ... */` for removals

Usage:
    python3 firefox-ios/Tuist/upgrade/ecosia-customizations-catalog.py --scan firefox-ios/ --output ecosia-customizations.json
    
Output: JSON catalog of all Ecosia customizations
"""

import re
import json
import argparse
from pathlib import Path
from typing import List, Dict, Any, Optional
from datetime import datetime
from dataclasses import dataclass, asdict


@dataclass
class EcosiaCustomization:
    """Represents a single Ecosia customization."""
    file_path: str
    line_number: int
    customization_type: str  # 'removal', 'substitution', 'addition'
    comment: str
    firefox_code: List[str]  # Original Firefox code (commented out)
    ecosia_code: List[str]   # Ecosia replacement
    context_before: List[str]  # 2 lines before for context
    context_after: List[str]   # 2 lines after for context
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for JSON serialization."""
        return {
            'file': self.file_path,
            'line': self.line_number,
            'type': self.customization_type,
            'comment': self.comment,
            'firefox_code': self.firefox_code,
            'ecosia_code': self.ecosia_code,
            'context_before': self.context_before,
            'context_after': self.context_after,
        }


def extract_context(lines: List[str], index: int, before: int = 2, after: int = 2) -> tuple[List[str], List[str]]:
    """Extract context lines before and after a given index."""
    context_before = []
    for i in range(max(0, index - before), index):
        if i < len(lines):
            context_before.append(lines[i].rstrip())
    
    context_after = []
    # After extraction depends on what we've already processed
    # This is filled in by the caller
    
    return context_before, context_after


def scan_file_for_customizations(file_path: Path) -> List[EcosiaCustomization]:
    """
    Scan a single Swift file for Ecosia customizations.
    
    Returns list of EcosiaCustomization objects.
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except Exception as e:
        print(f"⚠️  Warning: Could not read {file_path}: {e}")
        return []
    
    customizations = []
    i = 0
    
    while i < len(lines):
        line = lines[i]
        
        # Pattern 1: Multiline comment removal (/* Ecosia: ... */)
        if re.search(r'/\*\s*Ecosia:', line):
            custom = extract_multiline_removal(lines, i, file_path)
            if custom:
                customizations.append(custom)
                # Skip past the entire comment block
                i = custom.line_number + len(custom.firefox_code) + 3
                continue
        
        # Pattern 2: Inline comment (// Ecosia:)
        elif re.search(r'//\s*Ecosia:', line):
            custom = extract_inline_customization(lines, i, file_path)
            if custom:
                customizations.append(custom)
                # Continue from next line
                i += 1
                continue
        
        i += 1
    
    return customizations


def extract_multiline_removal(lines: List[str], start: int, file_path: Path) -> Optional[EcosiaCustomization]:
    """
    Extract a multiline removal customization.
    
    Pattern:
        /* Ecosia: Remove Glean
        import Glean
         */
    """
    try:
        comment_line = lines[start].strip()
        match = re.search(r'/\*\s*Ecosia:\s*(.*)', comment_line)
        if not match:
            return None
        
        comment = match.group(1).strip()
        
        # Find the closing */
        firefox_code = []
        i = start + 1
        while i < len(lines):
            if '*/' in lines[i]:
                break
            # Don't include empty lines
            code_line = lines[i].rstrip()
            if code_line:
                firefox_code.append(code_line)
            i += 1
        
        # Get context
        context_before, _ = extract_context(lines, start)
        context_after = []
        # Context after is lines after the closing */
        for j in range(i + 1, min(i + 3, len(lines))):
            context_after.append(lines[j].rstrip())
        
        return EcosiaCustomization(
            file_path=str(file_path),
            line_number=start + 1,  # 1-indexed
            customization_type='removal',
            comment=comment,
            firefox_code=firefox_code,
            ecosia_code=[],
            context_before=context_before,
            context_after=context_after,
        )
    except Exception as e:
        print(f"⚠️  Warning: Failed to extract multiline removal at {file_path}:{start+1}: {e}")
        return None


def extract_inline_customization(lines: List[str], start: int, file_path: Path) -> Optional[EcosiaCustomization]:
    """
    Extract an inline customization (addition or substitution).
    
    Pattern (Substitution):
        // Ecosia: update UA prefix
        // return clientUserAgent(prefix: "Firefox-iOS-Sync")
        return clientUserAgent(prefix: "Ecosia-iOS-Sync")
    
    Pattern (Addition):
        // Ecosia: Searches counter
        private let searchesCounter = SearchesCounter()
    """
    try:
        comment_line = lines[start].strip()
        match = re.search(r'//\s*Ecosia:\s*(.*)', comment_line)
        if not match:
            return None
        
        comment = match.group(1).strip()
        
        # Check if next lines are also comments (commented Firefox code)
        firefox_code = []
        i = start + 1
        while i < len(lines):
            line = lines[i].strip()
            if line.startswith('//') and not line.startswith('// Ecosia'):
                # This is commented-out Firefox code
                firefox_code.append(line[2:].strip())  # Remove //
                i += 1
            else:
                break
        
        # Next non-comment, non-empty lines are Ecosia code
        ecosia_code = []
        while i < len(lines):
            line = lines[i].rstrip()
            stripped = line.strip()
            
            # Stop at blank line, next comment, or closing brace at same level
            if not stripped or stripped.startswith('//') or (stripped == '}' and len(ecosia_code) > 0):
                break
            
            ecosia_code.append(line)
            i += 1
        
        # Determine type
        customization_type = 'substitution' if firefox_code else 'addition'
        
        # Get context
        context_before, _ = extract_context(lines, start)
        context_after = []
        for j in range(i, min(i + 2, len(lines))):
            context_after.append(lines[j].rstrip())
        
        return EcosiaCustomization(
            file_path=str(file_path),
            line_number=start + 1,  # 1-indexed
            customization_type=customization_type,
            comment=comment,
            firefox_code=firefox_code,
            ecosia_code=ecosia_code,
            context_before=context_before,
            context_after=context_after,
        )
    except Exception as e:
        print(f"⚠️  Warning: Failed to extract inline customization at {file_path}:{start+1}: {e}")
        return None


def scan_directory(scan_dir: Path, exclude_dirs: List[str] = None) -> tuple[List[EcosiaCustomization], Path]:
    """
    Recursively scan a directory for Swift files with Ecosia customizations.
    
    Args:
        scan_dir: Directory to scan
        exclude_dirs: List of directory names to exclude (e.g., ['Ecosia', 'EcosiaTests'])
    
    Returns:
        Tuple of (list of customizations, base_path for relative paths)
    """
    if exclude_dirs is None:
        exclude_dirs = ['Ecosia', 'EcosiaTests', 'Derived', 'build', '.build']
    
    all_customizations = []
    swift_files = []
    
    # Find all Swift files
    for swift_file in scan_dir.rglob('*.swift'):
        # Skip excluded directories
        if any(excluded in swift_file.parts for excluded in exclude_dirs):
            continue
        swift_files.append(swift_file)
    
    print(f"📁 Scanning {len(swift_files)} Swift files in {scan_dir}...")
    
    # Scan each file
    for swift_file in swift_files:
        customizations = scan_file_for_customizations(swift_file)
        if customizations:
            print(f"   ✓ {swift_file.relative_to(scan_dir)}: {len(customizations)} customization(s)")
            all_customizations.extend(customizations)
    
    return all_customizations, scan_dir.absolute()


def generate_catalog(customizations: List[EcosiaCustomization]) -> Dict[str, Any]:
    """Generate the JSON catalog structure."""
    # Count by type
    removals = [c for c in customizations if c.customization_type == 'removal']
    substitutions = [c for c in customizations if c.customization_type == 'substitution']
    additions = [c for c in customizations if c.customization_type == 'addition']
    
    # Group by file
    by_file = {}
    for custom in customizations:
        if custom.file_path not in by_file:
            by_file[custom.file_path] = []
        by_file[custom.file_path].append(custom)
    
    return {
        'version': '1.0',
        'generated_at': datetime.now().isoformat(),
        'total_customizations': len(customizations),
        'summary': {
            'total': len(customizations),
            'removals': len(removals),
            'substitutions': len(substitutions),
            'additions': len(additions),
            'files_affected': len(by_file),
        },
        'by_file': {
            file: len(customs) for file, customs in sorted(by_file.items())
        },
        'customizations': [c.to_dict() for c in sorted(customizations, key=lambda x: (x.file_path, x.line_number))],
    }


def print_summary(catalog: Dict[str, Any]):
    """Print a human-readable summary of the catalog."""
    print("\n" + "="*60)
    print("📊 ECOSIA CUSTOMIZATIONS CATALOG")
    print("="*60)
    print(f"Generated: {catalog['generated_at']}")
    print(f"\nTotal Customizations: {catalog['summary']['total']}")
    print(f"  • Removals:       {catalog['summary']['removals']:3d} (Firefox code commented out)")
    print(f"  • Substitutions:  {catalog['summary']['substitutions']:3d} (Firefox code replaced)")
    print(f"  • Additions:      {catalog['summary']['additions']:3d} (New Ecosia code)")
    print(f"\nFiles Affected: {catalog['summary']['files_affected']}")
    print("\nTop 10 Most Customized Files:")
    print("-"*60)
    
    top_files = sorted(catalog['by_file'].items(), key=lambda x: x[1], reverse=True)[:10]
    for file, count in top_files:
        print(f"  {count:2d}  {file}")
    
    print("="*60)


def main():
    parser = argparse.ArgumentParser(
        description='Catalog Ecosia customizations in the codebase',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Scan firefox-ios directory
  python3 firefox-ios/Tuist/upgrade/ecosia-customizations-catalog.py --scan firefox-ios/
  
  # Scan with custom output path
  python3 firefox-ios/Tuist/upgrade/ecosia-customizations-catalog.py --scan firefox-ios/ --output custom-catalog.json
  
  # Scan and only show summary (no file output)
  python3 firefox-ios/Tuist/upgrade/ecosia-customizations-catalog.py --scan firefox-ios/ --no-output
        """
    )
    
    parser.add_argument(
        '--scan',
        required=True,
        help='Directory to scan for Ecosia customizations'
    )
    parser.add_argument(
        '--output',
        default='ecosia-customizations.json',
        help='Output JSON file path (default: ecosia-customizations.json)'
    )
    parser.add_argument(
        '--no-output',
        action='store_true',
        help='Do not write output file, only print summary'
    )
    parser.add_argument(
        '--exclude',
        nargs='*',
        default=['Ecosia', 'EcosiaTests', 'Derived', 'build', '.build'],
        help='Directories to exclude from scan (default: Ecosia EcosiaTests Derived build .build)'
    )
    
    args = parser.parse_args()
    
    # Validate scan directory
    scan_dir = Path(args.scan)
    if not scan_dir.exists():
        print(f"❌ Error: Directory not found: {scan_dir}")
        return 1
    
    if not scan_dir.is_dir():
        print(f"❌ Error: Not a directory: {scan_dir}")
        return 1
    
    # Scan for customizations
    print(f"🔍 Scanning for Ecosia customizations in {scan_dir}...\n")
    customizations, base_path = scan_directory(scan_dir, exclude_dirs=args.exclude)
    
    # Make paths relative to base_path
    for custom in customizations:
        try:
            custom.file_path = str(Path(custom.file_path).relative_to(base_path))
        except:
            pass  # Keep absolute if relative_to fails
    
    if not customizations:
        print("\n⚠️  No Ecosia customizations found.")
        print("   This might indicate:")
        print("   - Scan directory doesn't contain Firefox code with Ecosia changes")
        print("   - Customizations use a different comment format")
        print("   - Customizations are in excluded directories")
        return 1
    
    # Generate catalog
    catalog = generate_catalog(customizations)
    
    # Write to file
    if not args.no_output:
        output_path = Path(args.output)
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(catalog, f, indent=2, ensure_ascii=False)
        print(f"\n📝 Catalog written to: {output_path}")
        print(f"   Size: {output_path.stat().st_size / 1024:.1f} KB")
    
    # Print summary
    print_summary(catalog)
    
    return 0


if __name__ == '__main__':
    import sys
    sys.exit(main())
