# Shared helpers for the sandbox orchestration scripts.
# Sourced by spawn / integrate / abandon / list-agents / orchestrate.
# Not executable on its own.

# Where worker worktrees live. Deliberately OUTSIDE /workspace so workers do
# not inherit the orchestrator's CLAUDE.md from an ancestor directory.
WORKTREE_ROOT="${WORKTREE_ROOT:-$HOME/worktrees}"

die() { echo "ERROR: $*" >&2; exit 1; }

# Root of the main working tree, even when called from inside a linked worktree.
repo_root() {
    git rev-parse --path-format=absolute --git-common-dir 2>/dev/null \
        | sed 's|/\.git$||'
}

# The branch the main worktree has checked out (the integration target).
base_branch() {
    git -C "$1" symbolic-ref --short HEAD 2>/dev/null || echo main
}

# Branch names double as tmux window names and worktree directory names, so
# keep them simple: kebab-case, no slashes.
valid_branch() {
    [[ "$1" =~ ^[a-z0-9][a-z0-9._-]*$ ]] && [[ "$1" != *..* ]] && [[ "$1" != *.lock ]]
}

project_id() {      # project_id <root> → readable name + stable path hash
    local root name hash
    root="$(cd "$1" 2>/dev/null && pwd -P)" || return 1
    name="$(basename "$root")"
    if command -v shasum >/dev/null 2>&1; then
        hash="$(printf '%s' "$root" | shasum -a 256 | awk '{print substr($1,1,10)}')"
    else
        hash="$(printf '%s' "$root" | cksum | awk '{print $1}')"
    fi
    printf '%s-%s\n' "$name" "$hash"
}

worktree_path() {   # worktree_path <root> <branch>
    local hashed legacy root_common legacy_common
    hashed="$WORKTREE_ROOT/$(project_id "$1")--$2"
    legacy="$WORKTREE_ROOT/$(basename "$1")--$2"
    if [[ -e "$hashed/.git" || ! -e "$legacy/.git" ]]; then
        echo "$hashed"
        return
    fi
    # Upgrade compatibility: adopt an already-registered basename-only
    # worktree only when it provably belongs to this repository. New worktrees
    # always use the collision-resistant path.
    root_common="$(git -C "$1" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
    legacy_common="$(git -C "$legacy" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
    if [[ -n "$root_common" && "$legacy_common" == "$root_common" ]]; then
        echo "$legacy"
    else
        echo "$hashed"
    fi
}

# All local branches except the base branch.
worker_branches() { # worker_branches <root>
    local base; base="$(base_branch "$1")"
    git -C "$1" for-each-ref refs/heads --format='%(refname:short)' \
        | grep -vx "$base" || true
}

# ── tmux helpers (always matched by exact window name, operated on by id) ────

# Session names carry the project (main repo directory) name so several
# projects can run their own orchestrator + workers on this machine at once.
agents_session() {  # agents_session → e.g. agents-myproject
    local root hashed legacy
    root="$(repo_root)"
    hashed="agents-$(project_id "$root")"
    legacy="agents-$(basename "$root")"
    if command -v tmux >/dev/null 2>&1 \
            && ! tmux has-session -t "$hashed" 2>/dev/null \
            && tmux has-session -t "$legacy" 2>/dev/null; then
        echo "$legacy"
    else
        echo "$hashed"
    fi
}

window_id() {       # window_id <name> → @id or empty
    tmux list-windows -t "$(agents_session)" -F '#{window_id} #{window_name}' 2>/dev/null \
        | awk -v n="$1" '$2 == n {print $1; exit}'
}

worker_window_live() {  # worker_window_live <branch>
    [[ -n "$(window_id "$1")" ]]
}

kill_branch_windows() { # kill_branch_windows <branch>
    local name id
    for name in "$1" "done-$1"; do
        id="$(window_id "$name")"
        if [[ -n "$id" ]]; then tmux kill-window -t "$id" 2>/dev/null || true; fi
    done
}

# ── worker state ─────────────────────────────────────────────────────────────

# .worker-done is written by the worker wrapper when claude exits; it contains
# the exit code. Its presence — not tmux window state — is the completion
# signal, so it survives container/tmux restarts.
worker_done_file() {    # worker_done_file <root> <branch>
    echo "$(worktree_path "$1" "$2")/.worker-done"
}

worker_exit_code() {    # worker_exit_code <marker> → exact non-negative integer
    local value
    [[ -f "$1" ]] || return 1
    IFS= read -r value < "$1" || true
    [[ "$value" =~ ^[0-9]+$ ]] || return 1
    printf '%s\n' "$value"
}

worker_resume_count() { # worker_resume_count <root> <branch>
    local wt
    wt="$(worktree_path "$1" "$2")"
    [[ -d "$wt" ]] || { echo 0; return; }
    find "$wt" -maxdepth 1 -type f -name '.worker-done.previous.*' 2>/dev/null \
        | wc -l | tr -d ' '
}

branch_blocked() {  # branch committed a BLOCKED.md?
    git -C "$1" cat-file -e "$2:BLOCKED.md" 2>/dev/null
}

running_workers() { # running_workers <root> → count of live worker windows
    local n=0 b
    while IFS= read -r b; do
        [[ -n "$b" ]] || continue
        if worker_window_live "$b" && [[ ! -f "$(worker_done_file "$1" "$b")" ]]; then
            n=$((n+1))
        fi
    done < <(worker_branches "$1")
    echo "$n"
}

# ── orchestration state hygiene ──────────────────────────────────────────────

# State files (GOAL.md, TASKS.md, QUESTIONS.md, DECISIONS.md) ARE committed —
# that's what makes remote operation work: push them and GitHub becomes the
# dashboard. Only runtime artifacts stay out of git: logs (huge transcripts),
# worker markers, and loop control files. Uses .git/info/exclude (shared by
# all worktrees) so workers running `git add -A` can never commit these.
ensure_excludes() { # ensure_excludes <root>
    local gitdir exclude line tmp
    gitdir="$(git -C "$1" rev-parse --path-format=absolute --git-common-dir)"
    exclude="$gitdir/info/exclude"
    mkdir -p "$gitdir/info"
    touch "$exclude"
    # Migration: earlier revisions excluded the state files — un-exclude them.
    tmp="$exclude.tmp"
    grep -vx -e GOAL.md -e TASKS.md -e QUESTIONS.md -e DECISIONS.md \
        "$exclude" > "$tmp" 2>/dev/null || true
    mv "$tmp" "$exclude"
    for line in logs/ STOP .release-done .orchestrator.pid '.worker-*'; do
        grep -qxF "$line" "$exclude" 2>/dev/null || echo "$line" >> "$exclude"
    done
}

# Cheap digest of everything the orchestrator reacts to. Used by the outer
# loop to back off polling when nothing is changing.
state_fingerprint() {   # state_fingerprint <root>
    local b
    {
        git -C "$1" rev-parse HEAD 2>/dev/null
        git -C "$1" for-each-ref refs/heads --format='%(refname) %(objectname)'
        cat "$1/TASKS.md" "$1/QUESTIONS.md" "$1/DECISIONS.md" "$1/ARCHITECTURE.md" \
            "$1/FEEDBACK.md" "$1"/design/*.md "$1"/design/screens/*.md 2>/dev/null
        while IFS= read -r b; do
            [[ -n "$b" ]] || continue
            if [[ -f "$(worker_done_file "$1" "$b")" ]]; then echo "done:$b"; fi
        done < <(worker_branches "$1")
        true
    } | cksum
}

# A question is "answered" the moment the human types text under its
# **Your answer:** line — they never touch the [PENDING]/[ANSWERED] marker;
# the orchestrator flips it. This prints "<total> <answered>": the number of
# ### [PENDING] question blocks, and how many of those already carry a
# non-empty answer. A block runs from its ### [PENDING] heading to the next
# ### or ## heading (or EOF); an answer is any non-blank line after the
# **Your answer:** line within that block. Callers derive "still awaiting the
# human" as total-answered, and treat answered>0 as work the LLM must process.
pending_answer_stats() { # pending_answer_stats <questions-file> → "<total> <answered>"
    [[ -f "$1" ]] || { echo "0 0"; return; }
    awk '
        function close_block() {
            if (pending) { total++; if (has_answer) answered++ }
            pending = 0; in_answer = 0; has_answer = 0
        }
        /^###[ \t]+\[PENDING\]/ { close_block(); pending = 1; next }
        /^###[ \t]/             { close_block(); next }
        /^##[ \t]/              { close_block(); next }
        {
            if (pending && $0 ~ /^\*\*Your answer:\*\*/) { in_answer = 1; next }
            if (in_answer && $0 ~ /[^ \t]/) has_answer = 1
        }
        END { close_block(); printf "%d %d\n", total + 0, answered + 0 }
    ' "$1"
}

section_item_count() {   # section_item_count <file> <exact ## heading>
    [[ -f "$1" ]] || { echo 0; return 1; }
    awk -v s="$2" '$0==s{f=1;next} /^##[[:space:]]/{f=0} f&&/^- /{n++} END{print n+0}' "$1"
}

validate_state_contract() { # validate_state_contract <root>
    local spec file heading count failed=0
    for spec in \
        'TASKS.md|## In Progress' 'TASKS.md|## Backlog' \
        'TASKS.md|## Done' 'TASKS.md|## Blocked' \
        'QUESTIONS.md|## Pending' 'QUESTIONS.md|## Answered' \
        'FEEDBACK.md|## Inbox' 'FEEDBACK.md|## Processed'; do
        file="${spec%%|*}"; heading="${spec#*|}"
        if [[ ! -f "$1/$file" ]]; then
            echo "state contract: missing $file" >&2
            failed=1
            continue
        fi
        count="$(grep -cFx -- "$heading" "$1/$file" 2>/dev/null || true)"
        if [[ "$count" != "1" ]]; then
            echo "state contract: $file must contain exactly one '$heading' (found $count)" >&2
            failed=1
        fi
    done
    return "$failed"
}

validate_goal_contract() {  # validate_goal_contract <GOAL.md>
    local heading count failed=0
    for heading in \
        '### ★ 3 · Vision, Goals & Non-Goals' \
        '### ★ 5 · User Stories & Acceptance Criteria' \
        '### ★ 6 · Functional Requirements' \
        '### ★ 8 · Technical Context & Constraints' \
        '### ★ 11 · Decision & Tradeoff Rules' \
        '### ★ 12 · Quality Bar' \
        '### ★ 13 · Escalation & Autonomy Boundaries' \
        '### ★ 15 · Definition of Done' \
        '### ★ 17 · Assumptions & Open Questions'; do
        count="$(grep -cFx -- "$heading" "$1" 2>/dev/null || true)"
        if [[ "$count" != "1" ]]; then
            echo "GOAL contract: expected exactly one '$heading' (found $count)" >&2
            failed=1
        fi
    done

    # Starred sections are executable autonomy policy. Reject unchanged
    # template prompts and empty list slots instead of letting them masquerade
    # as a filled specification.
    if ! awk '
        /^### ★ / { active=1; section=$0; next }
        active && (/^### / || /^## / || /^---$/) { active=0 }
        !active { next }
        /<!--/ { comment=1 }
        comment { if (/-->/) comment=0; next }
        /^- \*\*(One-line vision|Acceptable|Good):\*\*[[:space:]]*$/ ||
        /^[[:space:]]*-[[:space:]]*$/ ||
        /^[[:space:]]*- \[[[:space:]]*\][[:space:]]*$/ ||
        /^- \*\*\[(Must|Should|Could)\]\*\*[[:space:]]*$/ ||
        /\*\(Mandated, preferred, or "agent.s choice/ ||
        /\*\(Anything that must — or must not — be used/ ||
        /\*\(UI products: optionally fill the design\// ||
        /\*\(Core objects and their relationships/ ||
        /\*\(APIs, services, auth model/ ||
        /\*\(Budget, infra, latency, data residency/ ||
        /\*\(How to sequence when everything seems important/ ||
        /\*\(Move fast on reversible; pause on one-way doors/ ||
        /\*\(Tests — what kind and coverage/ ||
        /\*\(All of the above, plus:/ ||
        /^#### Feature area [0-9]+:[[:space:]]*$/ {
            printf "GOAL contract: unresolved placeholder in %s (line %d): %s\n", section, NR, $0 > "/dev/stderr"
            bad=1
        }
        END { exit bad }
    ' "$1"; then
        failed=1
    fi
    return "$failed"
}

# GNU timeout is used when present; stock macOS gets the process-group watchdog
# below. Either way, a hung child cannot silently outlive its deadline.
run_with_timeout() {    # run_with_timeout <secs> <cmd...>
    local secs="$1" pid timer rc marker
    shift
    if command -v timeout >/dev/null 2>&1; then
        timeout -k 30 "$secs" "$@"
        return
    fi

    # macOS does not ship GNU timeout. Job control puts the child in its own
    # process group so TERM/KILL reach descendants too (for example check.sh
    # spawning a test runner). A marker distinguishes our deadline from a
    # command that independently exits 143.
    marker="$(mktemp "${TMPDIR:-/tmp}/orch-timeout.XXXXXX")" || return 1
    rm -f "$marker"
    set -m
    "$@" &
    pid=$!
    set +m
    (
        sleep "$secs"
        if kill -0 "$pid" 2>/dev/null; then
            : > "$marker"
            kill -TERM -- "-$pid" 2>/dev/null || kill -TERM "$pid" 2>/dev/null || true
            sleep 30
            kill -KILL -- "-$pid" 2>/dev/null || kill -KILL "$pid" 2>/dev/null || true
        fi
    ) &
    timer=$!

    if wait "$pid"; then rc=0; else rc=$?; fi
    kill "$timer" 2>/dev/null || true
    wait "$timer" 2>/dev/null || true
    if [[ -f "$marker" ]]; then rc=124; fi
    rm -f "$marker"
    return "$rc"
}

# Print dirt outside the semantic state files that the orchestrator owns.
# Inbox/state edits may arrive while a run is live; source-code dirt must stop
# autonomous branching/integration because it cannot be merged safely.
non_state_dirty() {     # non_state_dirty <root>
    local path
    {
        git -C "$1" diff --name-only
        git -C "$1" diff --cached --name-only
        git -C "$1" ls-files --others --exclude-standard
    } 2>/dev/null | sort -u | while IFS= read -r path; do
        case "$path" in
            GOAL.md|TASKS.md|QUESTIONS.md|DECISIONS.md|ARCHITECTURE.md|FEEDBACK.md|REVIEW.md|CRITIQUE.md|design/*) ;;
            '') ;;
            *) printf '%s\n' "$path" ;;
        esac
    done
}

# True when the Anthropic API answers at the TCP/TLS level within seconds.
# Any HTTP response counts (401/404 are fine — we only care that the
# connection is not refused or black-holed). Without this probe, a dead
# network burns ~30 minutes inside claude's internal retry stack (0 tokens)
# before surfacing as "API Error: Unable to connect (ConnectionRefused)".
api_reachable() {
    curl -s -o /dev/null --connect-timeout 5 --max-time 15 \
        "${ANTHROPIC_BASE_URL:-https://api.anthropic.com}/v1/models"
}
