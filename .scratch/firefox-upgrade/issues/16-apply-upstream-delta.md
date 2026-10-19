# 16: Apply the upstream delta to the target

**Jira:** [MOB-5042](https://ecosia.atlassian.net/browse/MOB-5042)
**Milestone:** M3 Move to Firefox 157
**Status:** ready-for-human
**Blocked by:** 10, 11, 12, 13, 15

## What to build

`upgrade/firefox` moved from the 155.1 checkpoint to the upgrade target, as one commit, with every Ecosia customization preserved per the intent-diff manifest.

Apply the upstream changes against the recorded base, as described in [spec.md](../spec.md#moving-to-the-upgrade-target-m3):

```sh
git merge-tree --write-tree --merge-base=firefox-v155.1 HEAD <target-tag>
```

Resolve conflicts by type (removal, substitution, addition), check each customized file against its intent diff whether or not it conflicted, and record every conflict pattern in the diary. Pause any main sync while this is in progress, and run one immediately afterwards.

## Acceptance criteria

- [ ] One commit on `upgrade/firefox` moves the tree to the target, opened as a reviewed PR
- [ ] Every file in the manifest is checked against its intent diff, conflicted or not
- [ ] No conflict markers remain outside files that contain them on purpose
- [ ] `python3 ecosify-strings.py firefox-ios` has been run, with no Firefox or Mozilla branding in new strings
- [ ] Diary entry written, with each conflict pattern and any new trap
