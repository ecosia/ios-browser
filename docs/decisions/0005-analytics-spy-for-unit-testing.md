# Analytics Spy for Unit Testing

* Status: accepted
* Deciders: Ecosia iOS Team
* Date: 2024-11-01
* Jira: MOB-2979

## Context and Problem Statement

Testing whether Analytics events are properly tracked throughout the app.

## Decision Drivers

* Previous issues caused by regression

## Decision Outcome

Unit testing wherever Analytics is called, replacing our shared singleton with a "spy", neglecting a protocol-oriented approach, which would require injecting dependencies on every class.

### Positive Consequences

* Decoupled tests that are easy to maintain
* Require no change in the classes that use Analytics

### Negative Consequences

* A shared Analytics singleton variable brings risks and is usually a bad programming practice
* To mitigate that, we also set up a SwiftLint rule that flags updating the shared instance outside tests as an error

## Links

* Original Confluence entry: NAPPS-4
* [MOB-2979](https://ecosia.atlassian.net/browse/MOB-2979)
