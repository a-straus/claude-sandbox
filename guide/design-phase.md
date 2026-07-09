# Design phase & review cadence

Loaded on demand in the **first two iterations** (TASKS.md empty — design before
build) and **every ~5 integrations** (review cadence). **This file is the ONLY
procedure for the design phase and reviews — follow it; do not reconstruct the
draft/critique/reconcile flow from memory.**

## First iterations (TASKS.md is empty): design before build

Two minds design the architecture before any feature work starts:

- **Iteration 1 — draft.** Expand GOAL.md §8 into ARCHITECTURE.md: entities,
  relationships, and the conventions workers get wrong when left to guess (naming,
  ID strategy, timestamps, deletion policy, migration policy). If the product has a
  UI, settle the design contract (design/) in the same pass: a design/ the human
  already filled is the seeded contract — adopt it as-is (verify the ★ files are
  present, note gaps for the critic); if it is still the unfilled template, fill
  every file yourself (INDEX.md identity + principles, tokens.md, screens/,
  components.md, interaction.md, mockups.md). Commit. Then spawn exactly one worker
  — the critic, on the strong model at deep effort:
  `spawn --model "$ORCH_MODEL" --effort high --include GOAL.md --include design
  arch-critique "<brief>"`. Its brief: read GOAL.md, ARCHITECTURE.md, and the
  design contract (explicitly permitted — the critic alone reads all of design/),
  and challenge the design — missing entities, §3 scope creep, simpler
  alternatives, future pain points — committing findings to CRITIQUE.md. A
  human-seeded design contract is challenged for feasibility and GOAL.md conflicts
  only — taste is the human's. Spawn nothing else.
- **Iteration 2 — reconcile.** Integrate the critique branch. Adopt what survives
  scrutiny, reject what doesn't, record every contested call in DECISIONS.md,
  finalize ARCHITECTURE.md (and design/, if in play), `git rm CRITIQUE.md`, commit.
  THEN decompose GOAL.md into the Backlog: independent, worker-sized tasks with
  MoSCoW priorities, sequenced per §11 — thinnest end-to-end slice first. The first
  build task includes creating `check.sh`. When the design contract is in play, the
  first UI task is the design foundation, and it gets the strong model at deep
  effort (`spawn --model "$ORCH_MODEL" --effort high --include design/INDEX.md
  --include design/tokens.md --include design/components.md
  --include design/interaction.md design-foundation "..."`): materialize the
  tokens.md tokens verbatim as the project's token stylesheet and build the
  components.md base components as a real, composable component library. Tokens
  spent here pay rent on every UI task after — this brief is the one place a worker
  is pointed at the full tokens.md + components.md + interaction.md set; every later
  UI task composes the built library instead of inventing styles or re-reading the
  whole contract.

## Review cadence

Every ~5 integrations thereafter, queue a review task on the strong model at high
effort (`spawn --model "$ORCH_MODEL" --effort high --include GOAL.md
--include design review-NN "..."`): the reviewer reads GOAL.md, ARCHITECTURE.md,
and the design contract (read-only; reviewers, like the critic, read all of
design/), audits the recent diffs against them — UI diffs additionally for token
discipline (no raw visual values), component reuse, and microcopy conformance —
writes findings to REVIEW.md, and commits. Next iteration: read REVIEW.md, convert
real findings into Backlog items, `git rm REVIEW.md`, commit.
