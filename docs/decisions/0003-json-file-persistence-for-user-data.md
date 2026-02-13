# JSON File Persistence for User Data

* Status: accepted
* Deciders: Ecosia iOS Team
* Date: 2021-04-27
* Jira: MOB-2976

## Context and Problem Statement

Having persistence for user data and settings.

## Decision Drivers

* Loading user data via UserDefaults delayed the app launch
* UserDefaults could not scale
* UserDefaults was flaky in unit tests

## Decision Outcome

Storing the user data in JSON-encoded files [User.swift](https://github.com/ecosia/ios-browser/blob/mob-3113-firefox-upgrade-133/firefox-ios/Ecosia/Core/User.swift)

### Positive Consequences

* Ease of use
* Extensibility
* Speed of access
* Consistency
* Predictable unit test results

### Negative Consequences

* We need to implement persistence (storing, loading, caching) of the json-files ourselves

## Links

* Original Confluence entry: NAPPS-2
* [MOB-2976](https://ecosia.atlassian.net/browse/MOB-2976)
