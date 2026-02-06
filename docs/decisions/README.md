# Mobile Decision Records (MDR)

This directory contains Mobile Decision Records (MDR) for the Ecosia iOS Browser project.

## What is an MDR?

A Mobile Decision Record is a document that captures an important architectural or technical decision made for the mobile application, along with its context and consequences. We use the [MADR (Markdown Any Decision Records)](https://adr.github.io/madr/) template format.

There is a loose collection of old MRD style documents in our [jira](https://ecosia.atlassian.net/wiki/spaces/DEV/pages/3491397671/Native+Apps+Architectural+Decision+Records)

## Creating a new MDR

1. Copy the template from an existing MDR or use the MADR template
2. Name the file using the format: `NNNN-short-title.md` where `NNNN` is the next sequential number
3. Fill in all relevant sections
4. Submit a PR with the new MDR for review

## MDR Statuses

* **proposed** - The decision is being discussed
* **accepted** - The decision has been accepted and is in effect
* **deprecated** - The decision is no longer relevant
* **superseded** - The decision has been replaced by a newer decision

## Index

| ID | Title | Status | Date |
|----|-------|--------|------|
| [0001](0001-swiftlint-configuration-for-upstream-fork.md) | SwiftLint Configuration for Upstream Firefox Fork | Accepted | 2026-02-03 |
