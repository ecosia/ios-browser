# 02: Set up the isolated upgrade branch

**What to build:** The working surface every other ticket happens on, created without touching `main`. Squash all Ecosia commits since the actual fork point (verified via `git merge-base`, not the informally-cited version number) into a single commit on a new branch, tag the pre-rebase state as a safety net, then start the rebase onto the target Firefox release. Conflict resolution across every other ticket happens inside this one in-progress rebase — per the "single-commit rebase" decision, there is no intermediate `git rebase --continue` until ticket 19.

**Blocked by:** None (can start immediately).

**Status:** done

- [ ] `main` is untouched — verify no commits, tags, or refs on `main` changed
- [ ] A new branch exists with all Ecosia commits since the fork point squashed into exactly one commit
- [ ] A safety tag exists at the pre-squash / pre-rebase tip, cheaply reachable if the rebase needs to be abandoned and restarted
- [ ] `git rebase <target-tag>` has been started on the squashed commit and is sitting in-progress with conflicts surfaced
- [ ] The intent-diff manifest and symbol-dependency report (generated this session) are available on the branch or otherwise accessible to every subsequent ticket, rebaselined against the verified fork point
