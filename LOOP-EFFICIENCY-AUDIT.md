# CLAUDE.md load-frequency audit (branch: loop-efficiency-claudemd-advisor)

Goal: split the 392-line / 24 KB orchestrator CLAUDE.md (inherited as an ancestor
file by every project under `projects/<name>`, so re-read on EVERY orchestrator
iteration) into a lean always-loaded core + on-demand modules that load only when
the relevant situation arises.

Legend:
- **CORE** — needed (nearly) every iteration → stays in CLAUDE.md.
- **SITU** — needed only in specific situations → move to an on-demand module.
- **TRIM** — keep but tighten.

| Lines | Section | Label | Reasoning / destination |
|-------|---------|-------|-------------------------|
| 1–11 | Header / loop model (one invocation = one iteration) | CORE | Frames every iteration. Keep. |
| 13–44 | Operating style | CORE/TRIM | Behavioral guidance applies always, but ~30 lines is a lot; tighten to the load-bearing lines. |
| 48–68 | State-files table | CORE/TRIM | Every iteration reads state. Keep the table, but the verbose per-file prose (design/ breakdown, check.sh evolution rules) → compress; deep design/ rules already duplicated in design-phase module. |
| 72–75 | "The iteration" intro | CORE | Keep. |
| 76–226 | The 9-step iteration | SPLIT | The 9-step **skeleton** is CORE. Sub-details are SITU (below). |
| — step 1–3 (read/answers/feedback) | CORE | Every iteration. Keep concise. |
| — step 4 worker exit-code playbook (BLOCKED/exit 3/4/5/6/7 handling) | SITU | → module `worker-states`. Keep a 2-line pointer in core ("on any non-FINISHED worker, load worker-states"). |
| — step 5 trunk-green | CORE/TRIM | Frequent after integrations. Keep tight. |
| — step 6 spawn: model/effort routing tiers | CORE | Used most spawning iterations. Keep the tier table in core. |
| — step 6 spawn: design-contract `--include` rules (UI tasks) | SITU | → module `design-phase` (UI-only detail). |
| — step 7 escalation (§13 trigger + QUESTIONS format) | CORE/TRIM | Guardrail; keep the trigger list + the block format. |
| — step 8–9 bookkeeping / done-check | CORE | Every iteration. Keep. |
| 228–279 | "First iterations: design before build" + reviews cadence | SITU | ~52 lines. Only iterations 1–2 and every ~5th (reviews). → module `design-phase`. |
| 283–325 | The schema gate | SITU | ~43 lines. Only when a model-change is requested (rare). → module `schema-gate`. |
| 329–348 | Helpers in PATH table | CORE/TRIM | Orchestrator must know helpers exist. Keep the compact table; the sparse-checkout prose → shorten. |
| 352–382 | Hard rules | CORE | Guardrails, every iteration. Keep (tighten wording). |
| 386–392 | Network | SITU | Only on network failures (rare). → module `network`. |

## Proposed modules (on-demand)
1. `design-phase` — first-two-iteration design/critique flow, design-foundation
   spawn, review cadence, design-contract include rules. (~70 lines)
2. `schema-gate` — the full 7-step gate. (~43 lines)
3. `worker-states` — the exit-code → action playbook from step 4. (~24 lines)
4. `network` — allowlist + escalation. (~8 lines)

## Open mechanism question (for Fable)
How to make modules on-demand under headless `claude -p --dangerously-skip-permissions`:
- (A) Claude Code **skills** (`.claude/skills/<name>/SKILL.md`) — name+description
  always in context (cheap), body loads on invocation. Blog-recommended.
- (B) Plain **reference docs** (e.g. `guide/<name>.md`) that core CLAUDE.md tells
  the orchestrator to `Read` at the specific step. Dead simple, definitely works
  headlessly, but relies on the instruction firing.
- (C) Hybrid: docs in `.claude/skills/` with explicit "load X when Y" pointers in
  the core steps for determinism.

## Estimated result
Core CLAUDE.md ~180 lines / ~11 KB (from 392 / 24 KB). Situational ~145 lines
move out. Every routine iteration stops paying for schema-gate + design-phase +
network detail it isn't using.
