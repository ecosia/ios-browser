# EcosiaUpgrade

Ecosia-owned tooling, records and the diary for upgrading the Firefox code this app is built on. Nothing in this folder is part of any app or test target: Tuist does not reference it, and target source globs start with `Ecosia/`, which cannot match `EcosiaUpgrade/`.

## `UPSTREAM_BASE`

One line: the Firefox release tag, a tab, then that tag's full commit hash, followed by a newline.

```
firefox-v155.1	04df3bd66b34441c6b97ee3958535c5bf4633ca4
```

It names the Firefox release that this branch's Firefox code is built on. The upgrade was grafted onto `main` (ADR 0007), so `git merge-base` with a Firefox tag no longer finds this point, and the file records it instead.

**Who updates it:** whoever completes a move to a new upgrade target, in the same commit that completes the move.

**How it is used:** as the merge base when bringing in a newer Firefox release, for example:

```bash
base=$(cut -f1 firefox-ios/EcosiaUpgrade/UPSTREAM_BASE)
git merge-tree --write-tree --merge-base="$base" HEAD <new-tag>
```
