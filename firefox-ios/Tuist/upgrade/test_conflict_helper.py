"""
Test suite for ecosia-conflict-helper.py

Test-driven approach:
- Given: Ecosia customization in catalog
- Given: Git conflict in file with that customization
- Expect: Tool suggests correct resolution
"""

import pytest
import json
import tempfile
from pathlib import Path
from typing import Dict

# Import the module we're testing
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))

from ecosia_conflict_helper import (
    ConflictRegion,
    ConflictType,
    ResolutionStrategy,
    extract_conflicts,
    find_customization_in_conflict,
    analyze_conflict,
    generate_removal_resolution,
    generate_substitution_resolution,
    generate_addition_resolution,
)


# ============================================================================
# Test Fixtures
# ============================================================================

@pytest.fixture
def sample_catalog() -> Dict:
    """Sample catalog with different types of customizations."""
    return {
        'customizations': [
            {
                'file': 'AppDelegate.swift',
                'line': 10,
                'type': 'removal',
                'comment': 'Remove Glean',
                'firefox_code': ['import Glean'],
                'ecosia_code': [],
            },
            {
                'file': 'AppDelegate.swift',
                'line': 35,
                'type': 'substitution',
                'comment': "Swap Theme Manager with Ecosia's",
                'firefox_code': [
                    'lazy var themeManager = DefaultThemeManager()'
                ],
                'ecosia_code': [
                    'lazy var themeManager = EcosiaThemeManager()'
                ],
            },
            {
                'file': 'AppDelegate.swift',
                'line': 52,
                'type': 'addition',
                'comment': 'Searches counter',
                'firefox_code': [],
                'ecosia_code': [
                    'private let searchesCounter = SearchesCounter()'
                ],
            },
        ]
    }


@pytest.fixture
def temp_conflict_file():
    """Create a temporary file with conflicts."""
    temp_dir = tempfile.mkdtemp()
    temp_path = Path(temp_dir) / "test.swift"
    
    def _create_file(content: str) -> Path:
        temp_path.write_text(content)
        return temp_path
    
    yield _create_file
    
    # Cleanup
    if temp_path.exists():
        temp_path.unlink()
    Path(temp_dir).rmdir()


# ============================================================================
# Test: Extract Conflicts from File
# ============================================================================

def test_extract_conflicts_finds_single_conflict(temp_conflict_file):
    """
    GIVEN a file with one conflict marker
    WHEN extract_conflicts is called
    THEN it should find exactly one conflict region
    """
    # Arrange
    file_content = """
class Example {
<<<<<<< HEAD
    // Ecosia version
    let value = "ecosia"
=======
    // Firefox version
    let value = "firefox"
>>>>>>> firefox-v141.0
}
"""
    file_path = temp_conflict_file(file_content)
    
    # Act
    conflicts = extract_conflicts(str(file_path))
    
    # Assert
    assert len(conflicts) == 1
    assert conflicts[0].ecosia_version.strip() == '// Ecosia version\n    let value = "ecosia"'
    assert conflicts[0].firefox_version.strip() == '// Firefox version\n    let value = "firefox"'
    assert conflicts[0].firefox_branch == 'firefox-v141.0'


def test_extract_conflicts_finds_multiple_conflicts(temp_conflict_file):
    """
    GIVEN a file with multiple conflict markers
    WHEN extract_conflicts is called
    THEN it should find all conflicts
    """
    # Arrange
    file_content = """
class Example {
<<<<<<< HEAD
    let value1 = "ecosia"
=======
    let value1 = "firefox"
>>>>>>> firefox-v141.0

    func method() {
<<<<<<< HEAD
        print("ecosia")
=======
        print("firefox")
>>>>>>> firefox-v141.0
    }
}
"""
    file_path = temp_conflict_file(file_content)
    
    # Act
    conflicts = extract_conflicts(str(file_path))
    
    # Assert
    assert len(conflicts) == 2


# ============================================================================
# Test: Find Customization in Conflict
# ============================================================================

def test_find_customization_detects_removal(sample_catalog):
    """
    GIVEN a conflict containing commented Firefox code
    WHEN find_customization_in_conflict is called
    THEN it should find the removal customization
    """
    # Arrange
    conflict = ConflictRegion(
        file_path='AppDelegate.swift',
        start_line=10,
        ecosia_version='/* Ecosia: Remove Glean\nimport Glean\n */',
        firefox_version='import Glean',
        firefox_branch='firefox-v141.0'
    )
    
    # Act
    customization = find_customization_in_conflict(conflict, sample_catalog)
    
    # Assert
    assert customization is not None
    assert customization['type'] == 'removal'
    assert customization['comment'] == 'Remove Glean'


def test_find_customization_detects_substitution(sample_catalog):
    """
    GIVEN a conflict with Ecosia replacement code
    WHEN find_customization_in_conflict is called
    THEN it should find the substitution customization
    """
    # Arrange
    conflict = ConflictRegion(
        file_path='AppDelegate.swift',
        start_line=35,
        ecosia_version='lazy var themeManager = EcosiaThemeManager()',
        firefox_version='lazy var themeManager = DefaultThemeManager()',
        firefox_branch='firefox-v141.0'
    )
    
    # Act
    customization = find_customization_in_conflict(conflict, sample_catalog)
    
    # Assert
    assert customization is not None
    assert customization['type'] == 'substitution'
    assert "Swap Theme Manager" in customization['comment']


def test_find_customization_returns_none_for_standard_conflict(sample_catalog):
    """
    GIVEN a conflict with no Ecosia customization
    WHEN find_customization_in_conflict is called
    THEN it should return None
    """
    # Arrange
    conflict = ConflictRegion(
        file_path='OtherFile.swift',
        start_line=100,
        ecosia_version='let x = 1',
        firefox_version='let x = 2',
        firefox_branch='firefox-v141.0'
    )
    
    # Act
    customization = find_customization_in_conflict(conflict, sample_catalog)
    
    # Assert
    assert customization is None


# ============================================================================
# Test: Analyze Conflict
# ============================================================================

def test_analyze_conflict_identifies_removal_type(sample_catalog):
    """
    GIVEN a conflict involving a removal customization
    WHEN analyze_conflict is called
    THEN it should identify the conflict type as REMOVAL_REINTRODUCED
    """
    # Arrange
    conflict = ConflictRegion(
        file_path='AppDelegate.swift',
        start_line=10,
        ecosia_version='/* Ecosia: Remove Glean\nimport Glean\n */',
        firefox_version='import Glean',
        firefox_branch='firefox-v141.0'
    )
    
    # Act
    analyzed = analyze_conflict(conflict, sample_catalog)
    
    # Assert
    assert analyzed.conflict_type == ConflictType.REMOVAL_REINTRODUCED
    assert analyzed.resolution_strategy == ResolutionStrategy.KEEP_ECOSIA


def test_analyze_conflict_identifies_substitution_type(sample_catalog):
    """
    GIVEN a conflict involving a substitution customization
    WHEN analyze_conflict is called
    THEN it should identify the conflict type as SUBSTITUTION_CHANGED
    """
    # Arrange
    conflict = ConflictRegion(
        file_path='AppDelegate.swift',
        start_line=35,
        ecosia_version='lazy var themeManager = EcosiaThemeManager()',
        firefox_version='lazy var themeManager = DefaultThemeManager()',
        firefox_branch='firefox-v141.0'
    )
    
    # Act
    analyzed = analyze_conflict(conflict, sample_catalog)
    
    # Assert
    assert analyzed.conflict_type == ConflictType.SUBSTITUTION_CHANGED
    assert analyzed.resolution_strategy == ResolutionStrategy.UPDATE_COMMENT


def test_analyze_conflict_identifies_addition_type(sample_catalog):
    """
    GIVEN a conflict involving an addition customization
    WHEN analyze_conflict is called
    THEN it should identify the conflict type as ADDITION_MOVED
    """
    # Arrange
    conflict = ConflictRegion(
        file_path='AppDelegate.swift',
        start_line=52,
        ecosia_version='// Ecosia: Searches counter\nprivate let searchesCounter = SearchesCounter()',
        firefox_version='// Some other Firefox code',
        firefox_branch='firefox-v141.0'
    )
    
    # Act
    analyzed = analyze_conflict(conflict, sample_catalog)
    
    # Assert
    assert analyzed.conflict_type == ConflictType.ADDITION_MOVED
    assert analyzed.resolution_strategy == ResolutionStrategy.MERGE_BOTH


# ============================================================================
# Test: Generate Resolutions
# ============================================================================

def test_generate_removal_resolution_keeps_code_commented():
    """
    GIVEN a removal conflict (Firefox re-introduced removed code)
    WHEN generate_removal_resolution is called
    THEN it should generate resolution that keeps code commented
    """
    # Arrange
    conflict = ConflictRegion(
        file_path='AppDelegate.swift',
        start_line=10,
        ecosia_version='/* Ecosia: Remove Glean\nimport Glean\n */',
        firefox_version='import Glean',
        firefox_branch='firefox-v141.0'
    )
    customization = {
        'comment': 'Remove Glean',
        'firefox_code': ['import Glean'],
    }
    
    # Act
    resolution = generate_removal_resolution(conflict, customization)
    
    # Assert
    assert '/* Ecosia: Remove Glean' in resolution
    assert 'import Glean' in resolution
    assert '*/' in resolution


def test_generate_substitution_resolution_updates_firefox_code():
    """
    GIVEN a substitution conflict (Firefox changed code Ecosia replaced)
    WHEN generate_substitution_resolution is called
    THEN it should comment out new Firefox code and keep Ecosia replacement
    """
    # Arrange
    conflict = ConflictRegion(
        file_path='AppDelegate.swift',
        start_line=35,
        ecosia_version='lazy var themeManager = EcosiaThemeManager()',
        firefox_version='lazy var themeManager = DefaultThemeManager(param: value)',
        firefox_branch='firefox-v141.0'
    )
    customization = {
        'comment': "Swap Theme Manager with Ecosia's",
        'firefox_code': ['lazy var themeManager = DefaultThemeManager()'],
        'ecosia_code': ['lazy var themeManager = EcosiaThemeManager()'],
    }
    
    # Act
    resolution = generate_substitution_resolution(conflict, customization)
    
    # Assert
    assert "// Ecosia: Swap Theme Manager" in resolution
    assert '// lazy var themeManager = DefaultThemeManager(param: value)' in resolution
    assert 'lazy var themeManager = EcosiaThemeManager()' in resolution


def test_generate_addition_resolution_merges_both():
    """
    GIVEN an addition conflict (context around Ecosia code changed)
    WHEN generate_addition_resolution is called
    THEN it should merge Firefox changes and Ecosia addition
    """
    # Arrange
    conflict = ConflictRegion(
        file_path='AppDelegate.swift',
        start_line=52,
        ecosia_version='// Ecosia: Searches counter\nprivate let searchesCounter = SearchesCounter()',
        firefox_version='// New Firefox property\nprivate let newThing = Thing()',
        firefox_branch='firefox-v141.0'
    )
    customization = {
        'comment': 'Searches counter',
        'ecosia_code': ['private let searchesCounter = SearchesCounter()'],
    }
    
    # Act
    resolution = generate_addition_resolution(conflict, customization)
    
    # Assert
    assert 'private let newThing = Thing()' in resolution  # Firefox code
    assert '// Ecosia: Searches counter' in resolution  # Ecosia comment
    assert 'private let searchesCounter = SearchesCounter()' in resolution  # Ecosia code


# ============================================================================
# Integration Test: End-to-End
# ============================================================================

def test_end_to_end_conflict_resolution(temp_conflict_file):
    """
    INTEGRATION TEST
    
    GIVEN a file with Ecosia customization conflicts
    WHEN the full workflow is executed (extract → analyze → resolve)
    THEN it should produce correct resolutions for all conflicts
    """
    # Arrange
    file_content = """
import Foundation

class AppDelegate {
<<<<<<< HEAD
    /* Ecosia: Remove Glean
    import Glean
     */
=======
    import Glean
    import GleanMetrics
>>>>>>> firefox-v141.0

<<<<<<< HEAD
    // Ecosia: Swap Theme Manager with Ecosia's
    // lazy var themeManager = DefaultThemeManager()
    lazy var themeManager = EcosiaThemeManager()
=======
    lazy var themeManager = DefaultThemeManager(param: newValue)
>>>>>>> firefox-v141.0

<<<<<<< HEAD
    // Ecosia: Searches counter
    private let searchesCounter = SearchesCounter()
=======
    private let firefoxCounter = FirefoxCounter()
>>>>>>> firefox-v141.0
}
"""
    file_path = temp_conflict_file(file_content)
    
    # Create catalog matching this specific file path
    test_catalog = {
        'customizations': [
            {
                'file': str(file_path),
                'line': 10,
                'type': 'removal',
                'comment': 'Remove Glean',
                'firefox_code': ['import Glean'],
                'ecosia_code': [],
            },
            {
                'file': str(file_path),
                'line': 35,
                'type': 'substitution',
                'comment': "Swap Theme Manager with Ecosia's",
                'firefox_code': ['lazy var themeManager = DefaultThemeManager()'],
                'ecosia_code': ['lazy var themeManager = EcosiaThemeManager()'],
            },
            {
                'file': str(file_path),
                'line': 52,
                'type': 'addition',
                'comment': 'Searches counter',
                'firefox_code': [],
                'ecosia_code': ['private let searchesCounter = SearchesCounter()'],
            },
        ]
    }
    
    # Act
    conflicts = extract_conflicts(str(file_path))
    analyzed_conflicts = [analyze_conflict(c, test_catalog) for c in conflicts]
    
    # Assert
    assert len(analyzed_conflicts) == 3
    
    # Check removal conflict
    removal = analyzed_conflicts[0]
    assert removal.conflict_type == ConflictType.REMOVAL_REINTRODUCED
    assert removal.suggested_resolution is not None
    assert '/* Ecosia: Remove Glean' in removal.suggested_resolution
    
    # Check substitution conflict
    substitution = analyzed_conflicts[1]
    assert substitution.conflict_type == ConflictType.SUBSTITUTION_CHANGED
    assert substitution.suggested_resolution is not None
    assert 'EcosiaThemeManager()' in substitution.suggested_resolution
    
    # Check addition conflict
    addition = analyzed_conflicts[2]
    assert addition.conflict_type == ConflictType.ADDITION_MOVED
    assert addition.suggested_resolution is not None
    assert 'searchesCounter' in addition.suggested_resolution


# ============================================================================
# Run tests
# ============================================================================

if __name__ == '__main__':
    pytest.main([__file__, '-v'])
