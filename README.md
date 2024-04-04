# Ecosia for iOS

The iOS Browser that plants trees.

## Getting involved

**!!!** This project cannot be built by anyone outside of Ecosia (yet). **!!!**

There are dependencies that are not fully disclosed and thereby not available for the build. We are working on this. We'll update this note as soon we are able to ship the closed sources in binary form.

## Thank you note

Ecosia for iOS is based on a fork of the code of "Firefox for iOS". We want to express our gratitude to all the original contributors and Mozilla for releasing your code to the world.

## Building

-----------------
This branch works with [Xcode 14.3](https://developer.apple.com/download/more/?=xcode)

:construction: **Note**: For building on **Apple Silicon**, make sure you have selected _the Rosetta-based Simulators_ from Xcode list of devices.

1. Install the latest [Xcode developer tools](https://developer.apple.com/download/applications/) from Apple.
1. Install, [Brew](https://brew.sh), Node, and a Python3 virtualenv for localization scripts:

    ```shell
    brew update
    brew install node
    pip3 install virtualenv
    ```

1. Clone the repository:

    ```shell
    git clone git@github.com:ecosia/ios-browser.git
    ```

1. Install Node.js dependencies, build user scripts and update content blocker:

    ```shell
    cd ios-browser
    sh ./bootstrap.sh
    ```

    - If you run into a problem related to `content-blocker-lib-ios`, check the troubleshooting section [here](#missing-content-blocker-lib-ios-files).

1. Open the project

    ```bash
    open Client.xcodeproj
    ```

### Troubleshooting

#### Emulation support software not installed when running on Rosetta simulator

*Build error:* `iPhone 14 Pro supports emulating this architecture, but the emuluation support software is not installed`

*Reason:* Rosetta 2 needs to be installed

*Fix:* Open an app that needs Rosetta and you will be requested to install it. See [this link](https://support.apple.com/en-us/HT211861).

#### Missing content-blocker-lib-ios files

*Build error:* `content-blocker-lib-ios/Lists/some-file.json: No such file or directory`

*Reason:* If you get this error while building the project, probably something went wrong when running the `content_blocker_update.sh` script (which also runs as a step in `bootstrap.sh`).

In case the error was due to `xcrun: error: unable to lookup item 'PlatformPath'`, you might have the incorrect xcode sdk path. You can check it by running `xcrun --show-sdk-path --sdk macosx`, if it shows `/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk` it is incorrect.

*Fix:* Switch the default SDK location by running `sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer`.

#### Build configurations

The app is equipped by two custom Build Configurations for ad-hoc distribution over TestFlight and AppCenter.
The `Development_` prefix added to those two, serves the purpose of picking the correct `Core` module build configuration.

### CI/CD

Fastlane is used to push builds to the Appstore and to manage our certs and profiles. Follow the [docs](https://docs.fastlane.tools/getting-started/ios/setup/) to install. We recommend to use fastlane with bundler.

```shell
gem install bundler
bundle update
```

### Why is the `CURRENT_PROJECT_VERSION` set to `0`?

The `CURRENT_PROJECT_VERSION` being set to `0` indicates that it is not being used for local testing. The outcoming build number is updated by the CI, matching the CI run number (e.g. `8023`).

### Get certificates and profiles

Our certs and profiles are managed centrally by [fastlane match](https://docs.fastlane.tools/actions/match/). Find the repo [here](https://github.com/ecosia/IosSearchSigning)

Run `bundle exec fastlane match --readonly` to add certs and profiles to your system. You can append  `-p "keychain password"` to avoid keychain prompts during the process. The passphrase to decrypt the repo can be found in LastPass.

### Adding your own device

As we use `fastlane match` to hardwire profiles it gets a bit tricky to add a new device and run the app via your machine.

1. Plugin your device and add it to the portal via XCode-Prompt.
2. Login into [AppDeveloper Portal](https://developer.apple.com/account/)
3. Navigate to `Certificates, Identifiers & Profiles`
4. Select `Profiles`-Tab and find `match Development com.ecosia.ecosiaapp`
5. Edit it and make sure your device is selected
6. Save, download and double click the Profile
7. Now XCode should find it as it's in your keychain
8. Run on Device!

## TRANSLATIONS

We are using [Transifex](https://docs.transifex.com/client/introduction) for managing our translations.

### Install the transifex client using pip

```bash
curl -o- https://raw.githubusercontent.com/transifex/cli/master/install.sh | bash
```

#### Configure your `~/.transifexrc` file

```bash
[https://www.transifex.com]
api_hostname  = https://api.transifex.com
hostname      = https://www.transifex.com
username      = <vault secret>
password      = <vault secret>
rest_hostname = https://rest.api.transifex.com
token         = <vault secret>
```

### Translations need to be pulled and commited manually

Pulling translation from the web

```bash
tx pull -fs
```

Test and commit the new translations. There exists schemes for testing other languages in the simulator.

### Adding new strings

#### Via CLI

1. Pull the source file
2. Add the new strings to the English source file `Client/Ecosia/L10N/en.lproj/Ecosia.strings`
3. Push it to Transifex

```bash
tx pull -fs
tx push -s
```

### Update Mozilla Strings (only needed after upgrade)

We do a rebrand of the Strings from Mozilla. Usually this step is only needed after an upgrade as we keep our changes in version control (as of opposite to Mozilla).
First we need to import all the strings via the scripts:

```bash
# clone the repo
git clone https://github.com/mozilla-mobile/ios-l10n-scripts.git
# run the script in project-dir
./ios-l10n-scripts/import-locales-firefox.sh --release
```

After import we rebrand (aka "ecosify")

```bash
# brand all the files as they contain the term 'Firefox' a lot
python3 ecosify-strings.py Client
python3 ecosify-strings.py Extensions
python3 ecosify-strings.py Shared
```

## :rocket: Release

Follow the instructions from our [confluence page](https://ecosia.atlassian.net/wiki/spaces/MOB/pages/2460680288/How+to+release)

## How to update the release notes

Make sure that `fastlane` and `transifex`-cli is installed.

### Add source release notes to transifex (en-US)

> ℹ️ Updating the source file in the project and merging it into `main` will automatically push it to Transifex as well since the Github integration is in place.

> 🔔 Make sure that an _inflight_ version exists in AppStore Connect. If not, create one.

- Create a new branch off `main` and modify the English release notes [here](/fastlane/metadata/en-US/release_notes.txt)
- Open a PR with the modified English release note text file against `main` branch
- Once approved, *Squash and Merge* the code to `main`. (The transifex integration will pick up the push)
- Transifex will create a PR and update it with the release notes in all available languages :hourglass_flowing_sand:
- *Squash and Merge* the code to `main` via a PR and a GitHubAction workflow will be triggered to upload the newly translated release notes 

### Add language translations

- Make sure that all languages are translated in the transifex [web interface](https://app.transifex.com/ecosia/ecosia-ios-search-app/release_notestxt/) and found their way to `main`

- Verify the translations in the Transifex-made PR

- Squash and Merge the PR

- The GitHub Action Workflow `Upload release notes to AppStore` will take care of the upload

#### In case you need a manual update

- Push via the update translation via `deliver` to the AppStore

    ```bash
    bundle exec fastlane deliver --app-version 8.2.0
    ```
