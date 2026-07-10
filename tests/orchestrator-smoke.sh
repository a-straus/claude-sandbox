#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/bin/_lib.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }
tmp="$(mktemp -d "${TMPDIR:-/tmp}/orchestrator-test.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

# Completion records are exact, never digit-scraped.
for value in 0 12; do
    printf '%s\n' "$value" > "$tmp/marker"
    [[ "$(worker_exit_code "$tmp/marker")" == "$value" ]] || fail "valid marker $value"
done
for value in 'signal 9' -1 ''; do
    printf '%s\n' "$value" > "$tmp/marker"
    if worker_exit_code "$tmp/marker" >/dev/null 2>&1; then fail "accepted corrupt marker: $value"; fi
done

# Same basename, different absolute path => different runtime identity.
mkdir -p "$tmp/a/app" "$tmp/b/app"
[[ "$(project_id "$tmp/a/app")" != "$(project_id "$tmp/b/app")" ]] \
    || fail "project IDs collide"

# The macOS fallback is a real deadline, not an unbounded execution.
PATH=/usr/bin:/bin
started="$(date +%s)"
rc=0
run_with_timeout 1 bash -c 'sleep 20' 2>/dev/null || rc=$?
[[ "$rc" == 124 ]] || fail "portable timeout returned $rc"
(( $(date +%s) - started < 5 )) || fail "portable timeout was not prompt"

# Retrying is opt-in because stable IDs alone do not imply idempotency.
if "$ROOT/bin/attempt" run --run-id smoke --step-id unsafe --max-attempts 2 -- true \
        >/dev/null 2>&1; then
    fail "attempt allowed an unasserted retry-safe command"
fi

# Integration must roll back a clean textual merge whose combined result fails.
repo="$tmp/repo"
mkdir -p "$repo"
git -C "$repo" init -q -b main
git -C "$repo" config user.name Test
git -C "$repo" config user.email test@example.invalid
cp -R "$ROOT/bin" "$repo/bin"
printf '%s\n' '#!/usr/bin/env bash' \
    'test ! ( -f base.flag -a -f feature.flag )' > "$repo/check.sh"
printf '%s\n' original > "$repo/FEEDBACK.md"
chmod +x "$repo/check.sh"
git -C "$repo" add .
git -C "$repo" commit -qm base
git -C "$repo" branch feature
printf '%s\n' base > "$repo/base.flag"
git -C "$repo" add base.flag
git -C "$repo" commit -qm base-advance
base_before="$(git -C "$repo" rev-parse HEAD)"

WORKTREE_ROOT="$tmp/worktrees"
export WORKTREE_ROOT
wt="$(worktree_path "$repo" feature)"
mkdir -p "$WORKTREE_ROOT"
git -C "$repo" worktree add -q "$wt" feature
printf '%s\n' feature > "$wt/feature.flag"
git -C "$wt" add feature.flag
git -C "$wt" commit -qm feature
ensure_excludes "$repo"
printf '%s\n' 0 > "$wt/.worker-done"
printf '%s\n' 'human inbox edit' > "$repo/FEEDBACK.md"

rc=0
(cd "$repo" && CHECK_TIMEOUT_SECS=10 bin/integrate feature main) >/dev/null 2>&1 || rc=$?
[[ "$rc" == 5 ]] || fail "merged-result failure returned $rc, expected 5"
[[ "$(git -C "$repo" rev-parse main)" == "$base_before" ]] || fail "failed merge was not rolled back"
[[ -z "$(non_state_dirty "$repo")" ]] || fail "rollback left source dirt"
[[ "$(cat "$repo/FEEDBACK.md")" == 'human inbox edit' ]] || fail "rollback lost inbox edits"

# A finished worker has an explicit resume transition: archive the old marker,
# launch the same branch, and atomically publish a new exact marker.
fakebin="$tmp/fakebin"
mkdir -p "$fakebin"
printf '%s\n' '#!/usr/bin/env bash' 'echo "{}"' 'exit 0' > "$fakebin/claude"
chmod +x "$fakebin/claude"
PATH="$fakebin:/usr/bin:/bin"
(cd "$repo" && MAX_WORKERS=3 WORKER_TIMEOUT_SECS=10 bin/spawn --resume feature 'retry smoke') \
    >/dev/null
for _ in $(seq 1 100); do
    [[ -f "$wt/.worker-done" ]] && break
    sleep 0.1
done
if [[ "$(worker_exit_code "$wt/.worker-done" 2>/dev/null || true)" != 0 ]]; then
    find "$repo/logs" -type f -maxdepth 2 -print -exec tail -20 {} \; >&2 || true
    fail "resume did not publish exit 0"
fi
[[ "$(worker_resume_count "$repo" feature)" == 1 ]] || fail "resume marker was not archived"

echo "orchestrator smoke tests passed"
