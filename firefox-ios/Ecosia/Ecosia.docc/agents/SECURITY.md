# Security and Dependencies

Rules for changing dependencies, CI workflows or `.aikido`. The reasoning, current exclusions and known gaps are in [SECURITY_SCANNING.md](../SECURITY_SCANNING.md); read it before triaging an Aikido finding.

## Always

- Classify a finding before fixing it: shipped in the app (Swift packages, npm packages bundled into user scripts, generated Nimbus/Glean code), CI-only (Ruby gems, GitHub Actions) or unused.
- Ignore Aikido's "Service not internet-connected" downgrade for code that ships in the app.
- For dependencies inherited from Firefox, look for an upstream mozilla-mobile/firefox-ios pull request first and cherry-pick it with `-x`.
- Pin third-party GitHub Actions as `owner/repo@<full sha> # vX.Y.Z`.
- Set `persist-credentials: false` on new `actions/checkout` steps unless the job pushes with the checkout token.
- When changing an `exact:` Swift package pin, update every lockfile listed in `.github/scripts/check_pinned_dependencies.py`.
- Download remote scripts from a pinned commit and verify a checksum, like `.github/scripts/download_nimbus_fml.sh`.

## Ask First

- Adding or removing a path in `.aikido`.
- Bumping `AS_REF` or `NIMBUS_FML_SHA256` in `.github/scripts/download_nimbus_fml.sh`.

## Never

- Exclude a path from Aikido that is a Tuist target source, is bundled into the app, or is run by a workflow.
- Edit lockfiles that aren't part of our build just to close an Aikido finding; exclude them instead.
- Pipe a script from a moving branch (`main`, `master`) into a shell.
