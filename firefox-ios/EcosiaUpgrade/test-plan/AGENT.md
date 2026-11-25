# Running the plan as an agent

How a Claude Code session (or any agent with simulator control) runs the agent flows. A person can follow the same steps by hand. The format is in [README.md](README.md).

## 1. Builds

Two builds of the same scheme and configuration: the upgrade branch and `main` (production's code). Run them side by side; "matches main" is judged against the main build, not against memory.

```bash
# from the repository root of each checkout (one worktree per branch)
./tuist-setup.sh --no-open --skip-bootstrap
xcodebuild -scheme Ecosia -project firefox-ios/Client.xcodeproj -configuration Debug \
  -destination "id=$UDID" -clonedSourcePackagesDirPath firefox-ios/SourcePackages \
  -derivedDataPath "$DD" -skipMacroValidation -skipPackagePluginValidation build
app="$DD/Build/Products/Debug-iphonesimulator/Client.app"
```

- **Scheme:** `Ecosia` (bundle `com.ecosia.ecosiaapp`) talks to production. `EcosiaBeta` (`com.ecosia.ecosiaapp.firefox`) talks to staging; use it for flows with `signed in as`, because test accounts exist on staging only.
- A build takes about 11 GB of DerivedData. Keep one per branch, delete them after the run; check `df -h` before the second build.
- A main build that is a few days old is fine if no app code changed since: `git log --since=<build date> origin/main -- firefox-ios`. Record the commit either way.
- A built `.app` can be copied out of a simulator to reuse it: `xcrun simctl get_app_container <udid> com.ecosia.ecosiaapp app`.

## 2. Simulators

One simulator per build, same device and runtime, named after the ticket so other sessions leave them alone:

```bash
rt=com.apple.CoreSimulator.SimRuntime.iOS-26-5
up=$(xcrun simctl create "iPhone 13 mini MOB-5044" com.apple.CoreSimulator.SimDeviceType.iPhone-13-mini $rt)
mn=$(xcrun simctl create "iPhone 13 mini MOB-5044 main" com.apple.CoreSimulator.SimDeviceType.iPhone-13-mini $rt)
for u in $up $mn; do
  xcrun simctl boot $u
  xcrun simctl spawn $u defaults write -g AppleLanguages -array de-DE   # the run's locale
  xcrun simctl spawn $u defaults write -g AppleLocale -string de_DE
  xcrun simctl shutdown $u; xcrun simctl boot $u                        # the language applies after a reboot
done
xcrun simctl install $up "$upgrade_app"; xcrun simctl install $mn "$main_app"
```

- **iPhone 13 mini** is the default device: the smallest supported screen finds truncation and layout bugs first (MOB-5282). Add a large device (iPhone 17 Pro Max) for layout-heavy areas.
- **`fresh install`:** `xcrun simctl uninstall <udid> com.ecosia.ecosiaapp` then install again; `xcrun simctl erase <udid>` when the flow needs a clean device (redo the language step afterwards).
- **`update from main`:** install the main build, create the flow's state, then `xcrun simctl install <udid> "$upgrade_app"` over it. The data container survives, as on an App Store update.
- **`network off`:** there is no per-simulator switch; turn off the Mac's network for the step, or use the app's own offline state (load a page that fails, for example `https://ecosia.invalid`).
- **Launch arguments**, when a flow needs them: `xcrun simctl launch <udid> com.ecosia.ecosiaapp <args>`.

## 3. Driving the app

With Claude Code's iOS Simulator tool (`mcp__Claude_Code_iOS_Simulator__control`): `screenshot`, `tap` (a `duration` over 0.5 s is a long-press), `swipe`, `text`, `press_key`, `open_url`. Coordinates are device points (iPhone 13 mini: 375 × 812).

- Act on the screenshot you just took; take a new one after every navigation.
- **Home screen:** swipe up from the bottom edge (start within 4 pt of it). The HOME button action did nothing on Face ID devices (2026-11-25).
- Run each flow on both simulators before judging it: do the steps on the upgrade simulator, then the same steps on main, and compare the screenshots.
- **Opening a URL:** don't type it on a German simulator: the simulated keyboard turns `/` into `-` (2026-11-25). Open it through the app's scheme instead: `xcrun simctl openurl <udid> "ecosia://open-url?url=<percent-encoded URL>"` (it opens a new tab).
- **Taps during a sheet's dismissal are lost.** After closing a sheet or screen, take a screenshot before the next tap.
- **Simulator access:** the simulator tool asks the user once per simulator. Create the run's simulators while the user is there, or reuse ones they already allowed (reinstall the app for `fresh install`).
- Use the step's accessibility identifier where the tool can't see one, to describe what you tapped in the run file.
- System sheets (keyboard tips, permission prompts) can appear on first use; dismiss them and note it only if the app caused it.

## 4. Judging

A flow passes when every **Expect** line holds on the upgrade build. For "matches main":

- **Same:** pass.
- **Different, and listed under Intended changes in the target file:** pass; name the intended change in the note.
- **Different, not listed:** fail. Describe the difference in one line (what, where, which build looks right), attach both screenshots.
- **Wrong on both builds:** fail, with the note "also on main". It's a production bug, not an upgrade regression: it goes to `main` (and reaches the upgrade through the main sync), not to MOB-5047.
- **Couldn't run** (crash on launch, missing build, missing account): blocked, with the reason.

Look specifically for what manual QA found in MOB-5282: missing icons (an empty space where a button image should be), English text on a German device, text that is smaller or truncated compared with main, and the same screen differing by entry point.

## 5. Test accounts

The password never passes through the agent: copy it from the vault to the simulator's pasteboard in a shell, then paste in the field (long-press → Paste).

```bash
op read "op://<iOS QA vault>/<account item>/password" | xcrun simctl pbcopy <udid>
```

Type the account's email from the vault item's name or username field, never from a file in the repo. Sign in only on the beta build (`login.ecosia-staging.xyz`).

## 6. Recording

1. `firefox-ios/EcosiaUpgrade/tools/test_plan.py --todo <release> > runs/<release>/<date>-agent-<device>-<locale>.md` before starting.
2. Fill in each row as you go: result, one-line note, evidence link.
3. Fill in the header: builds (branch and commit of each), device, runtime, locale, runner (`agent: <model>` or a name).
4. Screenshots: keep both builds' images per failed or notable flow, named `<flow id>-upgrade.png` / `<flow id>-main.png`, and attach them to the regression ticket or the run's ticket. Not in git.
5. File every fail as a regression (child of MOB-5047) or record it as accepted, then write the diary entry.

Parallel runs: one subagent per area file is fine, as long as each has its own pair of simulators.
