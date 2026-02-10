# 7. Use .gitkeep Files for Tuist-Referenced Generated Directories

Date: 2026-02-10

## Status

Accepted

## Context

When migrating to Tuist for Xcode project generation (on branch firefox-upgrade-147.2-new-concurrency-fixes), we encountered an issue where several directories referenced in the Tuist configuration did not exist in the repository:

- `firefox-ios/Client/Generated/`
- `firefox-ios/Client/Generated/Metrics/`
- `firefox-ios/Sync/Generated/`
- `firefox-ios/Storage/Generated/`
- `focus-ios/Blockzilla/Generated/`

These directories are populated by build scripts during compilation:
- **Nimbus Feature Manifest Generator** creates `Client/Generated/FxNimbus.swift` and `Client/Generated/FxNimbusMessaging.swift`
- **Glean SDK Generator** creates `Client/Generated/Metrics/Metrics.swift`

The directories were already in `.gitignore` to prevent committing auto-generated files. However, when Tuist attempts to generate the Xcode project, it references these directories in the source file globs (e.g., `"Client/Generated/**/*.swift"`). The absence of these directories could cause warnings or issues during project generation.

### Forces at Play

1. **Build scripts generate files dynamically** - The content of these directories should not be committed to version control
2. **Tuist expects referenced directories to exist** - Project generation works more reliably when all referenced paths exist
3. **Team collaboration** - New developers cloning the repository need these directories to exist before running builds
4. **Merge conflicts** - We want to avoid directory structure issues during Firefox upstream merges

## Decision

We will create and maintain `.gitkeep` files in all build-generated directories that are referenced by Tuist configuration files. Specifically:

1. **Create .gitkeep files** in all Generated directories:
   - `firefox-ios/Client/Generated/.gitkeep`
   - `firefox-ios/Client/Generated/Metrics/.gitkeep`
   - `firefox-ios/Sync/Generated/.gitkeep`
   - `firefox-ios/Storage/Generated/.gitkeep`
   - `focus-ios/Blockzilla/Generated/.gitkeep`

2. **Update .gitignore** to ignore generated content while preserving directory structure:
   ```gitignore
   # Old pattern (ignores entire directory)
   firefox-ios/Client/Generated
   
   # New pattern (ignores content but keeps .gitkeep)
   firefox-ios/Client/Generated/*
   !firefox-ios/Client/Generated/.gitkeep
   !firefox-ios/Client/Generated/Metrics/
   firefox-ios/Client/Generated/Metrics/*
   !firefox-ios/Client/Generated/Metrics/.gitkeep
   ```

3. **Document the purpose** - Each .gitkeep file includes a comment explaining why it exists and what populates the directory.

## Consequences

### Positive

- **Tuist generates projects cleanly** - All referenced directories exist when running `tuist generate`
- **Better developer experience** - New developers can clone and run `tuist generate` immediately without build errors
- **Clearer intent** - The .gitkeep files with comments document which directories are auto-generated
- **Consistent structure** - All team members have the same directory structure after cloning

### Negative

- **Slight maintenance overhead** - If new Generated directories are added to Tuist config, we must remember to add corresponding .gitkeep files
- **Additional files in repository** - Five small .gitkeep files are added to version control

### Neutral

- **Standard practice** - Using .gitkeep for empty directories is a widely-accepted Git convention
- **No impact on build process** - Build scripts continue to generate files normally; .gitkeep files are harmless
- **No impact on .gitignore behavior** - Generated files are still properly ignored

### Future Considerations

If additional Generated directories are added to Tuist configurations in the future, this pattern should be followed:

1. Create the directory structure
2. Add a .gitkeep file with explanatory comment
3. Update .gitignore to exclude generated content while keeping .gitkeep
4. Document in the build scripts which files will be generated

This decision supports our broader Tuist adoption strategy by ensuring project generation works reliably across all development environments.
