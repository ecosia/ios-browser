# Testing

> Full snapshot testing guide for humans: [Ecosia/Ecosia.docc/SNAPSHOT_TESTING_WIKI.md](../SNAPSHOT_TESTING_WIKI.md)

## Requirements

- **MANDATORY**: Include tests when writing new code or implementing features
- Use Given/When/Then structure with minimal, relevant comments only
- Write unit tests using XCTest for business logic
- Place tests in `firefox-ios/EcosiaTests/` with clear file organization
- Place mocks in `firefox-ios/EcosiaTests/Mocks/`
- Test plan: `firefox-ios/EcosiaTests/UnitTest.xctestplan`

## Unit Tests

- Create testable implementations with injectable dependencies
- For protocol default implementations: verify actual dependencies are called, not mock call counts
- Test all accessibility features and edge cases
- Test performance scenarios and memory usage
- Follow TDD principles where appropriate

## Snapshot Tests

- Use `SnapshotBaseTests` base class with proper theme setup
- Config: `firefox-ios/EcosiaTests/SnapshotTests/snapshot_configuration.json`
- See `Ecosia/Ecosia.docc/SNAPSHOT_TESTING_WIKI.md` for full guide and the **coverage map**
- **When you change visible Ecosia UI** (`Ecosia/UI/**` or `Client/Ecosia/UI/**`), update or add snapshot tests and record references in the `SnapshotArtifacts` submodule in the same PR
- PR CI runs `check_snapshot_updates.sh` to ensure UI diffs include snapshot test or reference changes (bypass with the `skip-snapshot-check` label when there is no visual impact)

### Recording references

```bash
SNAPSHOT_TESTING_RECORD=all ./perform_snapshot_tests.sh \
  EcosiaTests/SnapshotTests/snapshot_configuration.json \
  EcosiaTests/SnapshotTests/environment.json \
  EcosiaTests/Results \
  EcosiaSnapshotTests
```

After adding a new snapshot test file, run `sh tuist-setup.sh` from the repo root, then commit both the parent repo and the `SnapshotArtifacts` submodule.

## Analytics Testing

- `Analytics.shared` must not be reassigned outside tests (SwiftLint custom rule)

## Running Tests

- Run via Xcode: `Cmd+U` with the **EcosiaBeta** scheme
- CI runs tests via GitHub Actions
