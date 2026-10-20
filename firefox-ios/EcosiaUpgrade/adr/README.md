# Upgrade ADRs

Architectural decisions made for the Firefox upgrade work. They live here, not in the repository's root `adr/` folder, because that folder belongs to Firefox: upstream adds its own numbered ADRs there with every release, so Ecosia files in it collide by number and conflict in `adr/README.md`.

Ecosia keeps its ADRs on Confluence. These are working copies: once the upgrade work is done, they move to Confluence and this folder is removed.

- [0001](0001-graft-firefox-upgrades-onto-main-via-upgrade-branch.md) - Graft Firefox Upgrades onto Main via a Long-Lived Upgrade Branch

Open: how ADRs carry on once `upgrade/firefox` is a long-lived branch next to `main`, so decisions made on either branch end up in one place (to decide with the team).
