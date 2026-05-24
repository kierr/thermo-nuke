#!/usr/bin/env bash
# test-pre-push.sh — tests for the pre-push version-bump gate.
# Pure bash, no additional dependencies beyond git and python3.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK="$SCRIPT_DIR/pre-push"

PASS=0
FAIL=0
TMPREPO=""

cleanup() {
  if [[ -n "$TMPREPO" && -d "$TMPREPO" ]]; then
    rm -rf "$TMPREPO"
  fi
}
trap cleanup EXIT

# Create a temporary git repo with a plugin.json
make_repo() {
  TMPREPO=$(mktemp -d -t test-pre-push.XXXXXX)
  cd "$TMPREPO"
  git init --quiet
  git config user.email "test@test.com"
  git config user.name "Test"
  mkdir -p .claude-plugin
}

# Write plugin.json with the given version and commit
commit_version() {
  local ver="$1"
  printf '{"name":"thermo-nuke","version":"%s","description":"test"}\n' "$ver" > .claude-plugin/plugin.json
  git add .claude-plugin/plugin.json
  git commit --quiet -m "version $ver"
}

# Simulate a pre-push stdin line.
# Usage: run_hook <local_sha> <remote_sha> <remote_ref>
# remote_ref defaults to refs/heads/main
run_hook() {
  local local_sha="$1"
  local remote_sha="$2"
  local remote_ref="${3:-refs/heads/main}"
  printf 'refs/heads/feature %s %s %s\n' "$local_sha" "$remote_ref" "$remote_sha" | bash "$HOOK"
}

assert_pass() {
  local desc="$1"; shift
  if run_hook "$@" 2>/dev/null; then
    PASS=$((PASS + 1))
    echo "  PASS: $desc"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL: $desc (expected pass, got failure)"
  fi
}

assert_fail() {
  local desc="$1"; shift
  if ! run_hook "$@" 2>/dev/null; then
    PASS=$((PASS + 1))
    echo "  PASS: $desc"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL: $desc (expected failure, got pass)"
  fi
}

echo "=== pre-push hook tests ==="

# --- Test 1: Push to non-main branch should pass ---
echo "--- Test 1: push to non-main branch ---"
make_repo
commit_version "0.1.0"
LOCAL=$(git rev-parse HEAD)
# Create a fake remote ref
FAKE_REMOTE=$(echo "0000000000000000000000000000000000000000")
assert_pass "non-main branch passes" "$LOCAL" "$FAKE_REMOTE" "refs/heads/feature"
cleanup
TMPREPO=""

# --- Test 2: Push to main with same version should fail ---
echo "--- Test 2: push to main with same version ---"
make_repo
commit_version "0.1.0"
REMOTE_SHA=$(git rev-parse HEAD)
# Make a non-version change so git sees a diff, but version stays the same
echo "# extra" >> .claude-plugin/plugin.json
git add .claude-plugin/plugin.json
git commit --quiet -m "other change, same version"
LOCAL_SHA=$(git rev-parse HEAD)
assert_fail "same version on main fails" "$LOCAL_SHA" "$REMOTE_SHA" "refs/heads/main"
cleanup
TMPREPO=""

# --- Test 3: Push to main with higher version should pass ---
echo "--- Test 3: push to main with higher version ---"
make_repo
commit_version "0.1.0"
REMOTE_SHA=$(git rev-parse HEAD)
commit_version "0.2.0"
LOCAL_SHA=$(git rev-parse HEAD)
assert_pass "higher version on main passes" "$LOCAL_SHA" "$REMOTE_SHA" "refs/heads/main"
cleanup
TMPREPO=""

# --- Test 4: Push to main with lower version should fail ---
echo "--- Test 4: push to main with lower version ---"
make_repo
commit_version "0.2.0"
REMOTE_SHA=$(git rev-parse HEAD)
commit_version "0.1.0"
LOCAL_SHA=$(git rev-parse HEAD)
assert_fail "lower version on main fails" "$LOCAL_SHA" "$REMOTE_SHA" "refs/heads/main"
cleanup
TMPREPO=""

# --- Test 5: First push (remote sha all zeros) should pass ---
echo "--- Test 5: first push to main (remote all zeros) ---"
make_repo
commit_version "0.1.0"
LOCAL_SHA=$(git rev-parse HEAD)
ZERO="0000000000000000000000000000000000000000"
assert_pass "first push to main passes" "$LOCAL_SHA" "$ZERO" "refs/heads/main"
cleanup
TMPREPO=""

# --- Test 6: Missing version should fail ---
echo "--- Test 6: push to main with missing version ---"
make_repo
# Commit with no version field
printf '{"name":"thermo-nuke","description":"test"}\n' > .claude-plugin/plugin.json
git add .claude-plugin/plugin.json
git commit --quiet -m "no version"
LOCAL_SHA=$(git rev-parse HEAD)
# Create a remote commit with a version
commit_version "0.1.0"
REMOTE_SHA=$(git rev-parse HEAD)
# Back to the no-version commit
git checkout --quiet "$LOCAL_SHA"
assert_fail "missing version on main fails" "$LOCAL_SHA" "$REMOTE_SHA" "refs/heads/main"
cleanup
TMPREPO=""

# --- Summary ---
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
