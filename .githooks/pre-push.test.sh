#!/bin/sh
# Ecosia: exercises the "print PR compare link" section of .githooks/pre-push.
#
# Not wired into CI — hooks are a local dev convenience (installed by bootstrap.sh),
# not part of the build. Run manually after editing pre-push:
#   sh .githooks/pre-push.test.sh

set -eu

script_dir=$(cd "$(dirname "$0")" && pwd)
hook="$script_dir/pre-push"
failures=0

# args: description, remote_name, remote_url, stdin, expected_grep_pattern (empty string = expect no output)
run_case() {
  description="$1"
  remote_name="$2"
  remote_url="$3"
  stdin_data="$4"
  expected="$5"

  output=$(printf '%s' "$stdin_data" | "$hook" "$remote_name" "$remote_url")
  status=$?

  if [ "$status" -ne 0 ]; then
    echo "FAIL: $description (hook exited $status, expected 0)"
    failures=$((failures + 1))
    return
  fi

  if [ -z "$expected" ]; then
    if [ -n "$output" ]; then
      echo "FAIL: $description (expected no output, got: $output)"
      failures=$((failures + 1))
    else
      echo "PASS: $description"
    fi
    return
  fi

  if echo "$output" | grep -qF "$expected"; then
    echo "PASS: $description"
  else
    echo "FAIL: $description (expected to find: $expected)"
    echo "  --- actual output ---"
    echo "$output" | sed 's/^/  /'
    failures=$((failures + 1))
  fi
}

z40=0000000000000000000000000000000000000000

# ecosia/ios-browser remote, pushing a new commit on a feature branch -> prints the compare link
run_case \
  "prints compare link for ecosia/ios-browser push" \
  "origin" "git@github.com:ecosia/ios-browser.git" \
  "refs/heads/my-feature abc123 refs/heads/my-feature def456
" \
  "https://github.com/ecosia/ios-browser/compare/main...my-feature?expand=1"

# https remote form should match too
run_case \
  "prints compare link for https remote URL" \
  "origin" "https://github.com/ecosia/ios-browser.git" \
  "refs/heads/another-branch abc123 refs/heads/another-branch def456
" \
  "https://github.com/ecosia/ios-browser/compare/main...another-branch?expand=1"

# unrelated remote -> no output at all
run_case \
  "stays silent for a non-ios-browser remote" \
  "origin" "git@github.com:some-org/some-other-repo.git" \
  "refs/heads/my-feature abc123 refs/heads/my-feature def456
" \
  ""

# deleting a remote branch (local_sha is all zeros) -> nothing to compare, no output
run_case \
  "stays silent when deleting a remote branch" \
  "origin" "git@github.com:ecosia/ios-browser.git" \
  "refs/heads/my-feature $z40 refs/heads/my-feature def456
" \
  ""

# branch names with slashes must keep their full path, not just the last segment
run_case \
  "preserves full branch name for feature/foo" \
  "origin" "git@github.com:ecosia/ios-browser.git" \
  "refs/heads/feature/foo abc123 refs/heads/feature/foo def456
" \
  "https://github.com/ecosia/ios-browser/compare/main...feature/foo?expand=1"

# pushing a tag isn't something you open a PR for -> no output
run_case \
  "stays silent when pushing a tag" \
  "origin" "git@github.com:ecosia/ios-browser.git" \
  "refs/tags/v1.0.0 abc123 refs/tags/v1.0.0 def456
" \
  ""

echo ""
if [ "$failures" -eq 0 ]; then
  echo "All pre-push hook tests passed."
  exit 0
else
  echo "$failures pre-push hook test(s) failed."
  exit 1
fi
