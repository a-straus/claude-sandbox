# Architecture

<!--
Owned by the orchestrator. Drafted from GOAL.md §8 in the first iteration,
challenged by a fresh-context critic agent, reconciled, then amended ONLY
through the schema-change gate (see CLAUDE.md): one model change in flight
at a time, applied while no other workers run.

Workers follow this document exactly and never edit it — integration is
refused for branches that touch it. Humans: read freely; steer it through
GOAL.md §8 and QUESTIONS.md answers, not by editing here.

Keep it operational, not aspirational — the things workers get wrong when
left to guess.
-->

## Entities & relationships

<!-- Core objects, their fields that matter, and how they relate. -->

## Conventions

<!-- The defaults every worker must follow, e.g.:
- Naming: snake_case tables, plural; camelCase in application code
- IDs: UUIDv7 primary keys
- Timestamps: created_at / updated_at on every table, UTC
- Deletion: soft-delete via deleted_at unless stated otherwise
- Migrations: one migration file per task, additive only unless gated
-->

## Boundaries & non-negotiables

<!-- What must not be done to this design without a schema-gate decision. -->

## Change log

<!-- One line per gated model change: date — change — requested by — outcome. -->
