#!/bin/bash
# Tests for sync-main.sh. Each case builds a throwaway repository with a `main` and an
# `upgrade` branch that share history, runs the script from the `upgrade` checkout and
# checks its exit code, output and the resulting repository state.
#
# Run: firefox-ios/EcosiaUpgrade/tools/sync-main.test.sh

set -uo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)
script="$script_dir/sync-main.sh"
failures=0
passes=0

fail() {
  echo "FAIL: $1"
  failures=$((failures + 1))
}

pass() {
  echo "PASS: $1"
  passes=$((passes + 1))
}

# Runs git with no user, system or hook configuration leaking into the test repositories.
git_test() {
  GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 git \
    -c user.name=Test -c user.email=test@example.com \
    -c core.hooksPath=/dev/null -c commit.gpgsign=false \
    -c init.defaultBranch=main "$@"
}

# Runs the script under test with the same isolated configuration.
run_script() {
  GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 \
    GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.com \
    GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@example.com \
    "$script" "$@"
}

# Creates a repository with one shared commit, a `main` branch and an `upgrade` branch
# checked out, and prints its path.
make_repo() {
  local repo
  repo=$(mktemp -d)
  git_test -C "$repo" init -q
  printf 'base\n' > "$repo/C"
  git_test -C "$repo" add C
  git_test -C "$repo" commit -q -m "base"
  git_test -C "$repo" switch -q -c upgrade
  echo "$repo"
}

commit_file() {
  local repo=$1 branch=$2 file=$3 content=$4
  git_test -C "$repo" switch -q "$branch"
  printf '%s\n' "$content" > "$repo/$file"
  git_test -C "$repo" add "$file"
  git_test -C "$repo" commit -q -m "$branch changes $file"
}

test_clean_merge() {
  local name="clean merge creates a merge commit with both sides"
  local repo out status head parents
  repo=$(make_repo)
  commit_file "$repo" main A "from main"
  commit_file "$repo" upgrade B "from upgrade"

  out=$(cd "$repo" && run_script --base-ref main)
  status=$?
  head=$(git_test -C "$repo" rev-parse HEAD)
  parents=$(git_test -C "$repo" rev-list --parents -n 1 HEAD | wc -w | tr -d ' ')

  if [ "$status" -ne 0 ]; then fail "$name (exit $status, expected 0)"
  elif [ "$parents" -ne 3 ]; then fail "$name (HEAD has $((parents - 1)) parents, expected 2)"
  elif [ ! -f "$repo/A" ] || [ ! -f "$repo/B" ]; then fail "$name (A or B missing after merge)"
  elif [ "$out" != "$head" ]; then fail "$name (stdout '$out', expected the new HEAD $head)"
  else pass "$name"
  fi
  rm -rf "$repo"
}

test_up_to_date() {
  local name="up to date exits 0 without a commit"
  local repo out status before after
  repo=$(make_repo)
  commit_file "$repo" upgrade B "from upgrade"
  before=$(git_test -C "$repo" rev-parse HEAD)

  out=$(cd "$repo" && run_script --base-ref main)
  status=$?
  after=$(git_test -C "$repo" rev-parse HEAD)

  if [ "$status" -ne 0 ]; then fail "$name (exit $status, expected 0)"
  elif [ "$out" != "already up to date" ]; then fail "$name (stdout '$out', expected 'already up to date')"
  elif [ "$before" != "$after" ]; then fail "$name (HEAD moved)"
  else pass "$name"
  fi
  rm -rf "$repo"
}

test_conflict() {
  local name="conflict exits 2, lists the file, leaves HEAD and tree untouched"
  local repo out status before after porcelain
  repo=$(make_repo)
  commit_file "$repo" main C "main's line"
  commit_file "$repo" upgrade C "upgrade's line"
  before=$(git_test -C "$repo" rev-parse HEAD)

  out=$(cd "$repo" && run_script --base-ref main 2>/dev/null)
  status=$?
  after=$(git_test -C "$repo" rev-parse HEAD)
  porcelain=$(git_test -C "$repo" status --porcelain)

  if [ "$status" -ne 2 ]; then fail "$name (exit $status, expected 2)"
  elif [ "$out" != "C" ]; then fail "$name (stdout '$out', expected exactly 'C')"
  elif [ "$before" != "$after" ]; then fail "$name (HEAD moved)"
  elif [ -n "$porcelain" ]; then fail "$name (working tree not clean: $porcelain)"
  else pass "$name"
  fi
  rm -rf "$repo"
}

test_dirty_tree() {
  local name="dirty working tree exits 1 without merging"
  local repo err status before after
  repo=$(make_repo)
  commit_file "$repo" main A "from main"
  git_test -C "$repo" switch -q upgrade
  printf 'uncommitted\n' >> "$repo/C"
  before=$(git_test -C "$repo" rev-parse HEAD)

  err=$(cd "$repo" && run_script --base-ref main 2>&1 >/dev/null)
  status=$?
  after=$(git_test -C "$repo" rev-parse HEAD)

  if [ "$status" -ne 1 ]; then fail "$name (exit $status, expected 1)"
  elif [ "$before" != "$after" ]; then fail "$name (HEAD moved)"
  elif [ -f "$repo/A" ]; then fail "$name (main's file appeared, so a merge ran)"
  elif ! grep -q "working tree not clean" <<<"$err"; then fail "$name (message was '$err')"
  else pass "$name"
  fi
  rm -rf "$repo"
}

test_bad_ref() {
  local name="unresolvable --base-ref exits 64"
  local repo status
  repo=$(make_repo)

  (cd "$repo" && run_script --base-ref nope >/dev/null 2>&1)
  status=$?

  if [ "$status" -ne 64 ]; then fail "$name (exit $status, expected 64)"
  else pass "$name"
  fi
  rm -rf "$repo"
}

test_not_a_repository() {
  local name="outside a git work tree exits 64"
  local dir status
  dir=$(mktemp -d)

  (cd "$dir" && GIT_CEILING_DIRECTORIES="$dir" run_script --base-ref main >/dev/null 2>&1)
  status=$?

  if [ "$status" -ne 64 ]; then fail "$name (exit $status, expected 64)"
  else pass "$name"
  fi
  rm -rf "$dir"
}

test_clean_merge
test_up_to_date
test_conflict
test_dirty_tree
test_bad_ref
test_not_a_repository

echo ""
if [ "$failures" -eq 0 ]; then
  echo "All $passes sync-main tests passed."
  exit 0
else
  echo "$failures of $((passes + failures)) sync-main tests failed."
  exit 1
fi
