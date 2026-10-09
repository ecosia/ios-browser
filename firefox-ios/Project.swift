import ProjectDescription
import ProjectDescriptionHelpers

/*
 Where to find what (Tuist/ProjectDescriptionHelpers/):
   BuildConfigurations.swift    — build configs + baseSettings
   Packages+Ecosia.swift        — SPM packages
   BuildScripts.swift           — client + extension build scripts
   ExtensionConfigurations.swift — 6 configs per extension (ShareTo, WidgetKit)
   Targets+Client.swift         — Client app target
   Targets+Extensions.swift     — ShareTo, WidgetKitExtension
   Targets+Frameworks.swift     — Account, Storage, Sync, Localizations, Ecosia, RustMozillaAppServices
   Targets+Tests.swift           — all test targets
   Schemes+Ecosia.swift         — Ecosia, EcosiaBeta, EcosiaSnapshotTests schemes
 */

// MARK: - Targets (order: extensions & frameworks first, then app, then tests)

let allTargets: [Target] =
    ExtensionTargets.all() +
    FrameworkTargets.all() +
    [ClientTarget.target()] +
    TestTargets.all()

// MARK: - Project

let project = Project(
    name: "Client",
    organizationName: "com.ecosia",
    options: .options(
        automaticSchemesOptions: .disabled,
        disableSynthesizedResourceAccessors: true
    ),
    packages: Packages.all,
    settings: .settings(configurations: BuildConfigurations.all),
    targets: allTargets,
    schemes: EcosiaSchemes.all,
    // Ecosia: Register root agent instruction files, CI configuration and
    // automation scripts as Xcode project files so they are browsable in Xcode
    // and indexable by the Coding Assistant. Files under Ecosia/Ecosia.docc/ are
    // already covered by the Ecosia framework target's resource glob and don't
    // need to be listed here.
    additionalFiles: [
        "../AGENTS.md",
        "../CLAUDE.md",
        // Globs rather than folder references: Tuist can't infer the `folder`
        // file type for a dot-prefixed directory, so Xcode shows it as an opaque
        // file. `**` doesn't recurse under one either, so each level is spelled
        // out and matched by extension to avoid picking up directories.
        .glob(pattern: "../.circleci/*.yml"),
        .glob(pattern: "../.github/workflows/*.yml"),
        .glob(pattern: "../.github/actions/*/action.yml"),
        .glob(pattern: "../.github/scripts/*.py"),
        .glob(pattern: "../.github/ISSUE_TEMPLATE/*.md"),
        .glob(pattern: "../*.sh"),
        .glob(pattern: "../*.py")
    ] + BuildConfigurations.additionalFiles,
)
