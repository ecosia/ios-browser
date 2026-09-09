# Coding Agent Instructions

Ecosia iOS Browser — a fork of Mozilla Firefox iOS with Ecosia customizations layered on top. Swift/SwiftUI, Xcode, MVVM.
**Build:** Tuist (project generation), Xcode, SwiftLint, webpack (user scripts)

Before any change: determine if the file is Firefox core or Ecosia-owned, and follow the commenting conventions in [firefox-ios/Ecosia/Ecosia.docc/agents/ARCHITECTURE.md](firefox-ios/Ecosia/Ecosia.docc/agents/ARCHITECTURE.md).

## Documentation

| When you need… | See |
| --- | --- |
| Always / Ask first / Never | [firefox-ios/Ecosia/Ecosia.docc/agents/BOUNDARIES.md](firefox-ios/Ecosia/Ecosia.docc/agents/BOUNDARIES.md) |
| Bootstrap, build, test, lint commands | [firefox-ios/Ecosia/Ecosia.docc/agents/COMMANDS.md](firefox-ios/Ecosia/Ecosia.docc/agents/COMMANDS.md) |
| What to do before changing code | [firefox-ios/Ecosia/Ecosia.docc/agents/CONTEXT.md](firefox-ios/Ecosia/Ecosia.docc/agents/CONTEXT.md) |
| PR naming, commits, code review | [firefox-ios/Ecosia/Ecosia.docc/agents/CODEREVIEW.md](firefox-ios/Ecosia/Ecosia.docc/agents/CODEREVIEW.md) |
| Firefox fork structure, commenting rules | [firefox-ios/Ecosia/Ecosia.docc/agents/ARCHITECTURE.md](firefox-ios/Ecosia/Ecosia.docc/agents/ARCHITECTURE.md) |
| Swift style, MVVM, theming, error handling | [firefox-ios/Ecosia/Ecosia.docc/agents/SWIFT.md](firefox-ios/Ecosia/Ecosia.docc/agents/SWIFT.md) |
| Ecosia.strings, Transifex, localization | [firefox-ios/Ecosia/Ecosia.docc/agents/LOCALIZATION.md](firefox-ios/Ecosia/Ecosia.docc/agents/LOCALIZATION.md) |
| XCTest, snapshots, mocks | [firefox-ios/Ecosia/Ecosia.docc/agents/TESTING.md](firefox-ios/Ecosia/Ecosia.docc/agents/TESTING.md) |
| Tuist project generation, new files | [firefox-ios/Ecosia/Ecosia.docc/agents/TUIST.md](firefox-ios/Ecosia/Ecosia.docc/agents/TUIST.md) |
| Swift Concurrency guide | [.cursor/skills/swift-concurrency/SKILL.md](.cursor/skills/swift-concurrency/SKILL.md) |

## Agent skills

### Issue tracker

Issues and specs are tracked locally as markdown under `.scratch/`. See [docs/agents/issue-tracker.md](docs/agents/issue-tracker.md).

### Domain docs

Multi-context: a root [CONTEXT-MAP.md](CONTEXT-MAP.md) points to one `CONTEXT.md` per context. See [docs/agents/domain.md](docs/agents/domain.md).
