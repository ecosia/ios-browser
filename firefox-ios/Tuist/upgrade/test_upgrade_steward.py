"""Tests for upgrade_steward ref validation."""

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).parent))

from upgrade_steward import verify_resolvable_ref


def test_verify_resolvable_ref_accepts_head():
    sha = verify_resolvable_ref("HEAD")
    assert len(sha) >= 7


def test_verify_resolvable_ref_rejects_missing_ref():
    with pytest.raises(RuntimeError, match="does not resolve"):
        verify_resolvable_ref("__upgrade_steward_nonexistent_ref__")
