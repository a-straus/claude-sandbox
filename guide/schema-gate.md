# The schema gate

Loaded on demand when a data-model change is requested (a worker commits BLOCKED.md
with first line `type: model-change`, or feedback/a task implies a schema change).
**This file is the ONLY procedure for a model change — run it in full; do not
improvise a schema change from memory.**

The data model is shared state; changing it concurrently is how parallel agents
destroy each other's work. Therefore: **at most one model change in flight, ever,
applied while nothing else runs.** You approve these changes yourself — the human is
never asked unless a §13 trigger is crossed.

1. **Request.** A worker that discovers it needs a schema change beyond what its
   brief grants does not make it — it commits BLOCKED.md with first line
   `type: model-change` (proposed change, why, impact) and exits.
2. **Drain.** On seeing one: record `MODEL CHANGE PENDING: <summary>
   (requested by <branch>)` under TASKS.md ## Blocked. Spawn nothing new. Let
   running workers finish; integrate them as they complete.
3. **Decide.** When nothing is running and nothing integrable remains: evaluate the
   request against GOAL.md §8/§3 and ARCHITECTURE.md. This is your call — approve,
   amend, or deny on your own authority; escalate only if it would cross a §13
   trigger (non-goal, irreversible data loss, paid dependency, external contract).
4. **Apply (if approved).** Update ARCHITECTURE.md (+ Change log) and DECISIONS.md,
   commit. Spawn ONE task, alone, on the worker model at deep effort
   (`--model "$WORKER_MODEL" --effort high`): apply the migration and adapt all
   affected code, check.sh green. The Opus orchestrator reviews and integrates it.
5. **Resume.** Clear the pending marker. Re-spawn the requester against the new base
   — its brief now quotes the updated model (its old branch may need redoing; that
   is expected and fine). Resume normal spawning.
6. **Queue.** Multiple pending requests are processed one per gate cycle — later
   requesters re-enter against the post-change world and must re-justify against the
   new ARCHITECTURE.md (their change may no longer be needed).
7. **Deny.** Record why in DECISIONS.md; re-spawn the requester with the prescribed
   workaround in its brief.

**Design changes are lighter — no gate.** The design contract (design/) has one
writer (you) but needs no ceremony: when an integration lands a new shared
component, or a task genuinely needs a token tokens.md lacks, fold it into the
contract yourself (components.md / tokens.md + an INDEX.md Change-log line) in the
same iteration, so the contract never trails the product by more than one pass.
Decide design questions from the seeded identity and principles — that is what they
are for; never ask the human to approve a component. The only design escalation is
replacing a human-seeded identity (INDEX.md D0/D1) wholesale — that is §13
territory; everything below it is yours.
