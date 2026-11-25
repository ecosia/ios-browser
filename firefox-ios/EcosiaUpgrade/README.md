# EcosiaUpgrade

Ecosia-owned tooling, records and the diary for upgrading the Firefox code this app is built on. Nothing in this folder is part of any app or test target: Tuist does not reference it, and target source globs start with `Ecosia/`, which cannot match `EcosiaUpgrade/`.

## `UPSTREAM_BASE`

One line: the Firefox release tag, a tab, then that tag's full commit hash, followed by a newline.

```
firefox-v155.1	04df3bd66b34441c6b97ee3958535c5bf4633ca4
```

It names the Firefox release that this branch's Firefox code is built on. The upgrade was grafted onto `main` ([upgrade ADR 0001](adr/0001-graft-firefox-upgrades-onto-main-via-upgrade-branch.md)), so `git merge-base` with a Firefox tag no longer finds this point, and the file records it instead.

**It must match the tree:** the recorded tag is the Firefox release whose code is actually on this branch. A wrong base makes the next Firefox merge compare against the wrong release.

**Who updates it:** whoever completes a move to a new upgrade target, in the same commit that completes the move.

**How it is used:** as the merge base when bringing in a newer Firefox release, for example:

```bash
base=$(cut -f1 firefox-ios/EcosiaUpgrade/UPSTREAM_BASE)
git merge-tree --write-tree --merge-base="$base" HEAD <new-tag>
```

## `inventory/`

One change inventory per upgrade target, named after the target release: [`159.1.md`](inventory/159.1.md). It lists what Firefox changed between the base and the target, release by release, marks each new feature and Nimbus flag **keep**, **out** or **needs product decision**, and ranks Ecosia's customized files by conflict risk. Write it before the merge; the merge works through it.

## `test-plan/`

The flows that check an upgrade against production, one Markdown file per area with a Mermaid diagram, readable by people and runnable by an agent on the iOS Simulator: [test-plan/README.md](test-plan/README.md). Each flow is an agent flow unless it names the test that automates it or the reason a person has to run it. It replaces the Miro test plan (Confluence "Firefox Upgrades", step 6). `tools/test_plan.py --check` keeps it complete; runs go in `test-plan/runs/<target>/`.
