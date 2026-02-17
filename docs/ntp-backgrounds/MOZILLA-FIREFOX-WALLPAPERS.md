# Mozilla Firefox iOS Wallpapers Documentation

> **Source**: This document is from the Mozilla Firefox iOS project.
> **Original**: https://github.com/mozilla-mobile/firefox-ios/wiki/Wallpapers
> **Retrieved**: 2026-02-17
> **License**: Mozilla Public License 2.0
>
> This documentation serves as the **official reference** for the wallpaper system that Ecosia iOS inherits from Firefox iOS.
>
> **How this file was obtained**:
> ```bash
> cd /tmp
> git clone https://github.com/mozilla-mobile/firefox-ios.wiki.git
> cp firefox-ios.wiki/Wallpapers.md docs/ntp-backgrounds/MOZILLA-FIREFOX-WALLPAPERS.md
> ```

---

# Overview

The wallpaper feature allows users to set a FireFox provided wallpaper as their background on the FireFox Homepage of the application. Once selected, the wallpaper will remain as the background even if that particular wallpaper was part of a limited time collection and is no longer available.

At the time of this writing, the user cannot upload their own wallpapers.

## Features of the wallpaper... feature

* Wallpaper information is not hardcoded through the use of metadata (delivered as JSON from the backend)
* Firefox only downloads thumbnails, to avoid downloading multiple large wallpaper files
* When a user is browsing wallpapers, the app only downloads requested wallpapers. Furthermore, upon leaving the settings screen, the app removes any large, unused wallpaper assets to save disk space.
* User may have an expried wallpaper set as their current wallpaper, but, upon selecting another one, they will lose their currently set one.

## Main Interface

Most of the work that's required in code is handled through the `WallpaperManager`'s public interfaces. These are:

```swift
 protocol WallpaperManagerInterface {
    var currentWallpaper: Wallpaper { get }
    var availableCollections: [WallpaperCollection] { get }
    var canOnboardingBeShown: Bool { get }
    var canSettingsBeShown: Bool { get }

    func setCurrentWallpaper(to wallpaper: Wallpaper, completion: @escaping (Result<Void, Error>) -> Void)
    func fetchAssetsFor(_ wallpaper: Wallpaper, completion: @escaping (Result<Void, Error>) -> Void)
    func removeUnusedAssets()
    func checkForUpdates()
    func migrateLegacyAssets()
}
```

* `currentWallpaper` - the currently set wallpaper; default value is the default wallpaper (`.type == .defaultWallpaper`)
* `availableCollections` - this returns an array of available wallpaper collections, based on date & locale. Each collection returned *may be* different from the metadata if the thumbnails for each wallpaper in the collection have not been downloaded. In other words, if the collection has three wallpapers, and only two thumbnails have downloaded, that collection will only have two wallpaper elements.
* `canOnboardingBeShown` - a boolean check to show whether or not the onboarding for wallpapers may be shown. This may be false given a few code documented circumstances.
* `canSettingsBeShown` - a boolean check for whether or not the wallpaper section can be shown in the settings section. This can be false given that not enough thumbnails have downloaded.
* `setCurrentWallpaper` - this function tries to set the passed in wallpaper as the current wallpaper. This information is saved in UserDefaults.
* `fetchAssetsFor` - if the user selects a wallpaper for which assets don't exist on the disk, this will fetch them from the server. These images are saved in the ApplicationSupport directory under a special wallpaper folder.
* `removeUnusedAssets` - this function should be called when unused assets should be removed (such as when leaving the settings screen). It removes all assets (large images & thumbnails) that are no longer used.
* `checkForUpdates` - This function will check to see if there's new metadata on the server, as well as attempt to download any missing thumbnail images. Note: while this may be called numerous times, the metadata check only happens once per day.
* `migrateLegacyAssets` - This migrates legacy wallpaper assets & currently set wallpapers, to the new system.

## Adding new wallpapers

Adding new wallpapers is done in two ways: first, they must be added to either a new or an existing collection in the metadata, and the assets must be uploaded to the marketing server in the appropriate folders.

### Wallpaper Metadata

Hello and welcome to the world of wallpaper metadata configuration. This
document outlines exactly what the metadata JSON should look like, what each object
inside it is, its type, what's optional and what's required. By following these
guidelines, you can ensure a successfull deployment of new wallpapers on the
mobile platforms.

#### Important Reminders

##### Versioning

Current version: `v1`

The wallpaper system uses a simple versioning system wherein the current version is contained in the respective version folder in the `metadata` folder (`v1`, `v2`, etc.) Please update the `wallpapers.json` file in the correct version folder.

##### Regarding Optional Fields

If a field is marked as optional, and you don't wissh to pass in a value, you must pass in `null` as the value. What a `null` value means for each particula field is covered in detail below.

##### Regarding Date Fields

All date fields require a string date to be in the form: "YYYY-MM-DD".

#### Metadata Object Definition

##### Main Metadata Object

The metadata object is made up of two main properties:

| Identifier          | Required | Type   | Definition                                                                                                                                                                                               |
|:--------------------|----------|--------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| "last-updated-date" | yes      | String | This date indicates the last time that the metadata object was updated. This is used by the applications to find out whether on not something is updated and new data must be downloaded. This must be written in "YYYY-MM-DD" format. |
| "collections"       | yes      | Array  | This is the array containing all the shipped collections. This must exist; if this is empty, no wallpapers will show up.                                                                                 |

##### Collections Object

The collections object is an array of collections. At the very least, one
collection must be present, which is the default "classicFirefox" collection. If
this array is not populated, then no wallpaper options will be shown to the user
when inspecting the wallpaper settings screen (or the wallpaper onboarding experience)


| Name                 | Required | Type       | Description                                                                                                                                                                                                                                            |
|:---------------------|:---------|:-----------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| "id"                 | yes      | String     | A string serving as a unique identifier for the collection.                                                                                                                                                                                            |
| "learn-more-url"     | no       | String     | The url that the collection is associated with. This is the URL that the user wil be taken to when they tap the "Learn More" button in the UI. A `null` value means that the "Learn More" button will not be dispalyed in the wallpaper settings page. |
| "available-locales"  | no       | Array      | An array of string locale IDs where the collection is available. These take the form of standard locale formats (eg. "en-US", or "pt-BR"). A `null` value in this field indicates that the collection is available for all locales.                    |
| "availability-range" | no       | Dictionary | A dictionary outlining the availability range. See below for more information.                                                                                                                                                                         |
| "wallpapers"         | yes      | Array      | An array of wallpaper objects. For more information, see below.                                                                                                                                                                                        |
| "heading"            | no       | String     | A custom title for a special wallpaper collection. A `null` value means that the default heading will be used.                                                                                                                                         |
| "description"        | no       | String     | A custom description for a special wallpaper collection. A `null` value means that the default heading will be used                                                                                                                                    |
| "heading"            | no       | String     | A custom title for a special wallpaper collection. A `null` value means that the default heading will be used.                                                                                                                                         |
| "description"        | no | String               | A custom description for a special wallpaper collection. A `null` value means that the default description will be used.         |

###### "availability-range"

| Name    | Required | Type   | Description                                                                                                                                                                                                                                                                                                 |
|:--------|:---------|:-------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| "start" | no       | String | The date on which the wallpaper collection is available. Data for the collection may be downloaded before, but the user will not see the collection before the given date. A `null` value means the collection is available immediately upon downloading the metadata. This must take the form "YYYY-MM-DD" |
| "end"   | no       | String | A date after which the collection is no longer available. A `null` value means the collection is available forever (or until removed from the metadata object). This must take the form "YYYY-MM-DD"                                                                                                        |

##### Wallpaper

| Name              | Required | Type   | Description                                                                                                                                                                                                                   |
|:------------------|:---------|:-------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| "id"              | yes      | String | A unique identifier to serve as the name of the wallpaper. This must be the same as the filenames in the assets folders. Failure to name the files or the identifier the same will result in a failure to download the files. |
| "text-color"      | yes      | String | A string represetation of a hex code for a color (ex "ADD8E6"). This colour will be used on the homepage for accessibility puposes.                                                                                           |
| "card-color"      | no       | String | A string represenattion of a hex code for a color (ex "ADD8E6"). This color will be used on the hmpeage if no blurring is possible on the various homepage elements.                                                          |
| "logo-text-color" | no       | String | A string represenattion of a hex code for a color (ex "ADD8E6"). This color will be used on the homepage's text logo.                                                                                                                                                                                                                              |


## Example JSON

```
{
    "last-updated-date": "2022-01-01",
    "collections": [
        {
            "id": "classic-firefox",
            "learn-more-url": null,
            "available-locales": null,
            "availability-range": null,
            "wallpapers": [
                {
                    "id": "wallpaperName",
                    "text-color": "0xADD8E6",
                }
            ],
            "heading": null,
            "description": null,
        },
        {
            "id": "autumnSunsets",
            "learn-more-url": "https://www.mozilla.com",
            "available-locales": ["en-US", "es-US", "en-CA", "fr-CA"],
            "availability-range": {
                "start": "2022-06-27",
                "end": "2022-09-30"
            },
            "wallpapers": [
                {
                    "id": "another-wallpaper-name",
                    "text-color": "0xADD8E6",
                }
            ],
            "heading": "Autumn - A Story in Orange",
            "description": "The best sunsets you'll find in the autumn.",
        }
    ]
}
```
