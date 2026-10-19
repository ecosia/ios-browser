# Firefox Upgrade

The process and vocabulary for reconciling Ecosia's customizations with a new upstream Firefox iOS release, and for keeping that work alive alongside ongoing development on `main`.

## Language

### Branches and bases

**Upstream base**:
The Firefox release tag (and its commit) that Ecosia's customization layer is currently built on. Recorded explicitly in the repository, because history alone cannot recover it.
_Avoid_: fork point, baseline, "the version we're on"

**Upgrade branch**:
A long-lived branch created from `main` that carries a newer upstream base while `main` keeps shipping production. It is kept current by merging `main` into it, becomes `main` only through migrating `main`, and is deleted afterwards.
_Avoid_: experimental branch, upgrade PR

**Upgrade target**:
The upstream Firefox release an upgrade aims for, fixed when work on it starts. Releases that ship afterwards are left for the next upgrade.
_Avoid_: latest Firefox

**Upgrade checkpoint**:
An intermediate upstream base that the upgrade branch builds and passes tests on, without being verified for production or released.
_Avoid_: milestone release, intermediate upgrade

**Migrating `main`**:
The team's decision and act of making the upgrade branch the new `main`, keeping the previous `main` as an archive branch named after its upstream base.
_Avoid_: cutover, merge the upgrade

**Graft**:
Placing an upgrade, built on Firefox's history, onto `main`'s history as a single commit whose parent is the `main` commit the upgrade was squashed from. This makes the upgrade branch a true descendant of `main`.
_Avoid_: rebase, transplant

**Main sync**:
Merging `main` into the upgrade branch so that new production work is carried across.
_Avoid_: forward-port, dual-landing

**Production parity**:
The state in which the upgrade branch has every behavior Ecosia ships in production, plus exactly the approved upstream features, verified against the current production build.
_Avoid_: feature complete, done

**Upgrade diary**:
The dated, running record of one upgrade: what was done, decided and discovered, whether by an engineer or an agent. Later upgrades, QA and the release-watching agent rely on it to understand why the code looks the way it does.
_Avoid_: changelog, notes, log

### Customizations

**Ecosia customization**:
A deliberate modification to Firefox-core code, marked inline with `// Ecosia: <reason>` (addition or substitution) or `/* Ecosia: <reason> ... */` wrapping the original Firefox code being replaced (removal).
_Avoid_: patch, override, hack

**Removal** (conflict type):
An Ecosia customization that deletes or comments out Firefox behavior entirely, with no replacement.

**Substitution** (conflict type):
An Ecosia customization that replaces Firefox behavior with different Ecosia behavior.

**Addition** (conflict type):
An Ecosia customization that adds new behavior alongside Firefox's, without removing anything.

**Promotional suppression**:
Shipping an upstream feature's function while disabling its user-facing callouts (badges, banners, contextual hints) through the feature's own configuration.

### Verification

**Intent-diff manifest**:
The diff of each Ecosia-modified file against the upstream base: the ground truth of what must survive an upgrade, independent of git's own conflict markers.
_Avoid_: patch file, changelog

**Symbol-dependency check**:
A static scan confirming that every Firefox-core symbol an Ecosia-owned file calls into still exists after an upgrade. A triage list, not a proof.
_Avoid_: dependency graph

**Vertical**:
A feature area (e.g. Toolbar, Main Menu, Homepage, Bookmarks) whose Ecosia-modified files share no overlap with any other vertical's, so it can be resolved independently.
