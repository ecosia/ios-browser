Firefox for iOS [![codebeat badge](https://codebeat.co/badges/67e58b6d-bc89-4f22-ba8f-7668a9c15c5a)](https://codebeat.co/projects/github-com-mozilla-firefox-ios) [![codecov](https://codecov.io/gh/mozilla-mobile/firefox-ios/branch/main/graph/badge.svg)](https://codecov.io/gh/mozilla-mobile/firefox-ios/branch/main)
===============

Download on the [App Store](https://apps.apple.com/app/firefox-web-browser/id989804926).


This branch (main)
-----------

This branch works with [Xcode 15](https://developer.apple.com/download/all/?q=xcode), Swift 5.8 and supports iOS 15 and above.

*Please note:* Both Intel and M1 macs are supported 🎉 and we use swift package manager.

Please make sure you aim your pull requests in the right direction.

For bug fixes and features for a specific release, use the version branch.

Getting involved
----------------

We encourage you to participate in this open source project. We love Pull Requests, Issue Reports, Feature Requests or any kind of positive contribution. Please read the [Mozilla Community Participation Guidelines](https://www.mozilla.org/en-US/about/governance/policies/participation/) and our [Contributing guidelines](https://github.com/mozilla-mobile/firefox-ios/blob/main/CONTRIBUTING.md) first. 

- You can [file a new issue](https://github.com/mozilla-mobile/firefox-ios/issues/new/choose) or research [existing bugs](https://github.com/mozilla-mobile/firefox-ios/issues)

If more information is required or you have any questions then we suggest reaching out to us via:
- Chat on Element channel [#fx-ios](https://chat.mozilla.org/#/room/#fx-ios:mozilla.org) for general discussion, or write DMs to specific teammates for questions.
- Open a [Github discussion](https://github.com/mozilla-mobile/firefox-ios/discussions) which can be used for general questions.

Want to contribute on the codebase but don't know where to start? Here is a list of [issues that are contributor friendly](https://github.com/mozilla-mobile/firefox-ios/labels/Contributor%20OK), but make sure to read the [Contributing guidelines](https://github.com/mozilla-mobile/firefox-ios/blob/main/CONTRIBUTING.md) first. 

Building the code
-----------------

1. Install the latest [Xcode developer tools](https://developer.apple.com/xcode/downloads/) from Apple.
1. Install, [Brew](https://brew.sh), Node, and a Python3 virtualenv for localization scripts:
    ```shell
    brew update
    brew install node
    pip3 install virtualenv
    ```
1. Clone the repository:
    ```shell
    git clone https://github.com/mozilla-mobile/firefox-ios
    ```
1. Install Node.js dependencies, build user scripts and update content blocker:
    ```shell
    cd firefox-ios
    sh ./bootstrap.sh
    ```
1. Open `Client.xcodeproj` in Xcode.
1. Make sure to select the `Fennec` [scheme](https://developer.apple.com/documentation/xcode/build-system?changes=_2) in Xcode.
1. Select the destination device you want to build on.
1. Run the app with `Cmd + R` or by pressing the `build and run` button.

⚠️ Important: In case you have dependencies issues with SPM, please try the following:
- Xcode -> File -> Packages -> Reset Package Caches

Building User Scripts
-----------------

User Scripts (JavaScript injected into the `WKWebView`) are compiled, concatenated, and minified using [webpack](https://webpack.js.org/). User Scripts to be aggregated are placed in the following directories:

```none
/Client
|-- /Frontend
    |-- /UserContent
        |-- /UserScripts
            |-- /AllFrames
            |   |-- /AtDocumentEnd
            |   |-- /AtDocumentStart
            |-- /MainFrame
                |-- /AtDocumentEnd
                |-- /AtDocumentStart
```

This reduces the total possible number of User Scripts down to four. The compiled output from concatenating and minifying the User Scripts placed in these folders resides in `/Client/Assets` and are named accordingly:

* `AllFramesAtDocumentEnd.js`
* `AllFramesAtDocumentStart.js`
* `MainFrameAtDocumentEnd.js`
* `MainFrameAtDocumentStart.js`

To simplify the build process, these compiled files are checked-in to this repository. When adding or editing User Scripts, these files can be re-compiled with `webpack` manually. This requires Node.js to be installed, and all required `npm` packages can be installed by running `npm install` in the project's root directory. User Scripts can be compiled by running the following `npm` command in the root directory of the project:

```shell
npm run build
```

License
-----------------

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

> ℹ️ Updating the source file in the project and merging it into `main` will automatically push it to Transifex as well since the Github integration is in place

- Make sure that an _inflight_ version exists in AppStore Connect. If not, create one.
- Add English text to release notes in AppStore Connect
- Download metadata from AppStore specifying the inflight version

    ```bash
    bundle exec fastlane deliver download_metadata --app-version 8.2.0
    ```

- Merge the code to main via a PR (The transifex integration will pick up the push)

- Wait for translators :hourglass_flowing_sand:

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
