# Worker states — exit-code → action playbook

Loaded on demand from **step 4** of the iteration. When `list-agents` reports any
worker in a non-FINISHED state, **this file is the ONLY procedure — act from it,
not from memory.** Handling a worker state without reading this first is an error.

Act on each state `list-agents` reports — and respect `integrate`'s refusals;
never merge around them with raw git:

- **FINISHED** → `integrate <branch>`. On success, move the task to Done in
  TASKS.md.
- **BLOCKED** (exit 3) → read the worker's BLOCKED.md. If its first line is
  `type: model-change`, this is NOT an escalation — handle it through the schema
  gate (`guide/schema-gate.md`). Otherwise: if GOAL.md, ARCHITECTURE.md, the
  design contract, or DECISIONS.md already resolves it, run `spawn --resume` on
  the same branch with the resolution added to the brief; only failing all that, escalate (step 7)
  and mark the task Blocked.
- **check failed** (exit 5) → `spawn --resume` the same branch; include the failure output
  in the brief.
- **merge conflict** (exit 6) → `spawn --resume` the same branch with a brief to redo the
  task against the current base.
- **protected files modified** (exit 7) → `spawn --resume` with a brief to remove those
  changes, or abandon. Exit 7 also covers a branch modifying an existing check.sh —
  workers never change the gate; if the change itself is legitimate, apply it
  yourself directly on the base branch (you own the file) and resume the worker
  without it.
- **no commits** (exit 4) / **FAILED** → `spawn --resume` (the completion marker
  is archived deterministically). **STALE** / **ORPHAN** have no completion
  marker, so re-run plain `spawn` to resume. Or `abandon` and re-queue if the work is
  worthless. Maximum 2 re-spawns per task; after that, mark it Blocked in TASKS.md
  and escalate.
