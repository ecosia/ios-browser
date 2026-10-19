# 7. Graft Firefox Upgrades onto Main via a Long-Lived Upgrade Branch

Date: 2026-10-01

## Status

Accepted

## Context

Ecosia's iOS browser is a fork of Firefox iOS. Ecosia's customizations sit on top of an upstream Firefox release, and every upgrade must move that layer onto a newer release. The upgrade to Firefox v147.2 was done as a single-commit rebase: every Ecosia commit was squashed into one, rebased onto the new Firefox tag, and `main`'s history was replaced with the result.

The experimental upgrade to Firefox v155.1 followed the same technique on a branch built on Firefox's history. By the time it built and passed its tests, `main` had moved on by about two dozen pull requests. The upgrade could not be merged into `main`, because the two branches share no recent history, and landing it would have meant replacing `main`'s history again. That forces every open feature branch to be rebased and makes the upgrade a single high-risk cutover.

At the same time, `main` must keep shipping production releases while the upgrade is verified, and it cannot receive partial upgrade work.

## Decision

We will graft each upgrade onto `main`'s history instead of replacing `main`.

The upgrade is first built on Firefox's history as before. We then create a single commit whose content is the upgraded tree and whose parent is the `main` commit the Ecosia layer was squashed from. A long-lived branch, `upgrade/firefox`, starts from that commit. Because it now descends from `main`, we keep it current by merging `main` into it, automatically after every merge to `main`, with conflicts handed to the branch owner. Changes reach the upgrade branch only through reviewed pull requests, with the same CI checks as `main`.

When the team decides the upgrade has reached production parity, we migrate `main`: we keep the current `main` as an archive branch named after its Firefox version (for example `main-147`), which also serves as the base for any patch to the previous production version, then fast-forward `main` to the upgrade branch and delete the upgrade branch. This replaces the earlier procedure of cherry-picking `main`'s commits onto the upgrade branch and then renaming and force-pushing branches.

Because Firefox's history is no longer an ancestor of our branches, `git merge-base` can no longer tell which Firefox release we are built on. We will record the upstream base (release tag and commit) explicitly in `firefox-ios/EcosiaUpgrade/`, and later upgrades will apply the upstream delta against that recorded base, for example with `git merge-tree --merge-base=<recorded tag> HEAD <new tag>`.

## Consequences

`main`'s history is never rewritten by an upgrade, so open feature branches are unaffected, and migrating `main` no longer requires temporarily allowing force pushes on a protected branch. Ongoing production work reaches the upgrade branch in small, frequent merges rather than in one large reconciliation at the end. When this was first tried for v155.1, merging two weeks of `main` into the grafted branch conflicted in only four files.

Each upgrade appears in our history as one large commit. `git blame` on Firefox-core code points at that commit rather than at the individual Mozilla commits; Mozilla's history remains available in the upstream repository.

The recorded upstream base becomes a piece of state that must be kept accurate. If it drifts from reality, the next upgrade will compute the wrong upstream delta.

Merging `main` into the upgrade branch can complete without conflicts and still break behavior, for example when `main` changes code that the upgrade restructured elsewhere. Every main sync therefore has to build and run the test suites, not only merge.
