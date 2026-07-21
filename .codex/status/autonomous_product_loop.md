# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Reconcile V2 replacement station-pressure evidence to exact source reports.

Status:
Complete; ready to publish.

Selection evidence:
- Replacement ranking emits required station-pressure penalties and optional
  ordered allocation/calendar source paths, but runtime validation currently
  checks only arithmetic, known paths, and nonzero evidence presence.
- A row can therefore claim pressure for the wrong candidate or wrong embedded
  report and still validate after its ranking score is adjusted.
- Repair execution already derives exact pressure candidate IDs separately from
  the live station-calendar report and candidate-refresh allocation report.

Intended behavior:
- Consolidate those exact IDs into one shared candidate-ID to sorted source-path
  map used by both producer and validator.
- Reconcile every ranking row's required station penalty and optional source
  list to embedded source reports and the declared `risk_weight`.
- Preserve allocation-only, calendar-only, dual-source deduplication, nominal,
  zero-weight, semantic-priority, and deterministic-order behavior.
- Add wrong-candidate, wrong-source, arithmetic-consistent penalty, nominal,
  dual-source, and checked-fixture coverage; document the executable guarantee.

Level 6 pillar advanced:
Fleet contact/station selection explanations backed by exact embedded evidence.

Last published slice:
- `8c11ea0e` Reconcile V2 contact intent pressure evidence (`3709 passed`).

Likely files:
- repair station-pressure derivation and replacement-selection modules
- V2 campaign-repair runtime contract modules
- station/allocation ranking and schema tests
- V2 capability and roadmap docs

Verification:
- Focused allocation/calendar ranking and contract tests: `11 passed`.
- Repair-path suite: `72 passed`.
- Campaign-repair schema fixtures: `11 passed`.
- Schema suite plus schema-lint task tests: `389 passed`.
- Campaign-planner suite: `759 passed`.
- Full suite: `3709 passed`.
- `mix format --check-formatted`, `mix compile --warnings-as-errors`, and
  `git diff --check` passed.
- Runtime-only reconciliation required no generated schema changes.

Review:
- Producer and validator share one allocation/calendar candidate-source map;
  candidate identity, dual-source deduplication, and lexical ordering cannot
  drift locally.
- Allocation-only, calendar-only, dual-source, nominal, and zero-weight rows
  all validate against their exact embedded evidence.
- Arithmetic-consistent wrong penalties and known-but-wrong source paths are
  rejected at stable row paths.
- Malformed report rows are ignored by derivation so existing structural
  validators can report them without the cross-field validator raising.

Remaining maturity gaps:
- Continue candidate-specific resource/contact/readiness selection or ranking
  effects only where stable identity evidence supports them.
- Continue fleet-scale station/allocation decisions while preserving explicit
  provider and Cadence execution boundaries.
- Continue broader schema/versioned compatibility discipline and stale-input
  challenge fixtures.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent is performing bounded
mapping, implementation, review, and mechanical publish checks.
