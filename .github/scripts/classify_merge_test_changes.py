#!/usr/bin/env python3

import sys
from pathlib import PurePosixPath


SNAPSHOT_ONLY_PREFIXES = (
    ".cursor/",
    ".github/ISSUE_TEMPLATE/",
    ".github/actions/perform_snapshot_tests/",
    "firefox-ios/Ecosia/Ecosia.docc/",
    "firefox-ios/EcosiaTests/SnapshotTests/",
)

SNAPSHOT_ONLY_FILES = {
    ".github/PULL_REQUEST_TEMPLATE.md",
    ".github/workflows/snapshot_tests.yml",
    "check_snapshot_updates.sh",
    "generate_snapshot_coverage_docs.sh",
    "perform_snapshot_tests.sh",
}


def requires_merge_tests(path: str) -> bool:
    normalized_path = str(PurePosixPath(path))
    if normalized_path.endswith(".md"):
        return False
    if normalized_path in SNAPSHOT_ONLY_FILES:
        return False
    return not normalized_path.startswith(SNAPSHOT_ONLY_PREFIXES)


def main() -> None:
    changed_paths = sys.argv[1:]
    relevant_paths = [path for path in changed_paths if requires_merge_tests(path)]
    should_run = not changed_paths or bool(relevant_paths)

    print(f"should_run={'true' if should_run else 'false'}")
    if relevant_paths:
        print("Merge tests required by:", file=sys.stderr)
        for path in relevant_paths:
            print(f"  {path}", file=sys.stderr)
    elif changed_paths:
        print("Only documentation or snapshot-test files changed; merge tests can be skipped.", file=sys.stderr)
    else:
        print("No changed paths were supplied; running merge tests conservatively.", file=sys.stderr)


if __name__ == "__main__":
    main()
