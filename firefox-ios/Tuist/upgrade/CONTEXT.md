# Firefox Upgrade

The process, tooling, and vocabulary for reconciling Ecosia's customizations against a new upstream Firefox iOS release.

## Language

**Ecosia customization**:
A deliberate modification to Firefox-core code, marked inline with `// Ecosia: <reason>` (addition or substitution) or `/* Ecosia: <reason> ... */` wrapping the original Firefox code being replaced (removal). This convention is what makes customizations machine-parsable across an upgrade.
_Avoid_: patch, override, hack.

**Removal** (conflict type):
An Ecosia customization that deletes or comments out Firefox behavior entirely, with no replacement. On upgrade, the resolution is to keep the new Firefox code commented out alongside it, preserving the removal.

**Substitution** (conflict type):
An Ecosia customization that replaces Firefox behavior with different Ecosia behavior. On upgrade, the resolution is to update the commented-out original to Firefox's new version, then re-adapt Ecosia's replacement to it.

**Addition** (conflict type):
An Ecosia customization that adds new behavior alongside Firefox's, without removing anything. On upgrade, the resolution is to merge both versions.

**Fork point**:
The specific upstream Firefox commit that Ecosia's current customization layer is actually built on — found via `git merge-base`, not the version number developers informally cite. These can drift apart (the layer was informally called "on top of 147.1"; the actual fork point is 147.2).

**Single-commit rebase**:
The upgrade technique: squash every Ecosia commit since the fork point into one commit, in isolation on a dedicated branch, then `git rebase <new-firefox-tag>` that one commit — resolving all resulting conflicts in one continuous pass before a single `--continue`. Chosen over rebasing Ecosia's commits individually, which re-opens conflict resolution on the same file once per commit that touches it.
_Avoid_: incremental rebase, per-commit rebase.

**Intent-diff manifest**:
The precomputed diff of each Ecosia-modified file against the fork point — the ground truth of "what must survive" an upgrade, independent of git's own conflict markers. Necessary because a 3-way merge can resolve "cleanly" while silently orphaning Ecosia behavior that depended on code Firefox restructured elsewhere.
_Avoid_: patch file, changelog.

**Symbol-dependency check**:
A static scan confirming every Firefox-core symbol an Ecosia-owned file calls into still exists after an upgrade. Catches silent structural loss — a renamed or deleted method with no textual conflict anywhere near Ecosia's own lines.
_Avoid_: dependency graph (implies more rigor than this heuristic actually provides — it's a triage list, not a proof).

**Vertical**:
A feature area (e.g. Toolbar, Main Menu, Homepage, Bookmarks) whose Ecosia-modified files share no overlap with any other vertical's. Verticals can be resolved in parallel — by different engineers or agents — without one's changes colliding with another's.

**Promotional suppression**:
Shipping a Firefox feature's actual function while disabling its user-facing callouts — via that feature's own separate flag/variable for badges, banners, or contextual hints — rather than disabling the feature outright. Used when a feature is fine to have but not to actively surface (e.g. Ad Blocker: `enabled: true`, `badge-enabled: false`).
