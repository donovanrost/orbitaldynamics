# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Reconcile V2 replacement candidate values to source candidates.

Status:
Complete; ready to publish.

Selection evidence:
- Ranking contracts require numeric candidate values and reconcile final row
  arithmetic/order, but do not prove a row's `candidate_score` came from the
  matching embedded `source_candidate_activities` entry.
- A row can therefore inflate or deflate candidate value, adjust ranking score,
  and remain structurally valid.
- Current producer rows are built directly from the normalized source candidate
  set, which provides a deterministic exact-ID reconciliation surface.

Intended behavior:
- Resolve every replacement-ranking candidate ID to exactly one embedded source
  candidate and recompute its numeric/default-zero candidate value.
- Reject missing, ambiguous, or value-mismatched source candidate explanations
  even when ranking arithmetic and order remain internally consistent.
- Preserve extensible candidate activity types, existing selection semantics,
  default-zero values, and checked V2 artifact compatibility.
- Add exact value tamper, missing/ambiguous source identity, default-zero, and
  checked-fixture coverage; document the executable cross-field guarantee.

Level 6 pillar advanced:
Explainable V2 ranking values backed by durable embedded candidate evidence.

Last published slice:
- `86ba5897` Reconcile V2 station pressure evidence (`3709 passed`).

Likely files:
- V2 campaign-repair runtime contract modules
- replacement-ranking schema/planner tests
- V2 capability and roadmap docs

Verification:
- Focused ranking/source-handoff contract tests: `5 passed`.
- Campaign-repair schema fixtures: `11 passed`.
- Schema suite plus schema-lint task tests: `389 passed`.
- Campaign-planner suite: `759 passed`.
- Full suite: `3709 passed`.
- `mix format --check-formatted`, `mix compile --warnings-as-errors`, and
  `git diff --check` passed.
- Runtime-only reconciliation required no generated schema changes.

Review:
- Each ranking row now resolves through exact candidate identity to one and only
  one source candidate; malformed non-map source rows remain structural errors
  rather than raising in cross-field validation.
- Numeric candidate values are compared with the same tolerance used by other
  V2 arithmetic contracts after the source candidate's own score/term contract
  validates it.
- Corrected ranking arithmetic cannot mask a missing, duplicated, or altered
  source candidate value.

Remaining maturity gaps:
- Continue exact V2 ranking/score reconciliation for replayable source fields.
- Continue fleet-scale station/allocation decisions while preserving explicit
  provider and Cadence execution boundaries.
- Continue broader schema/versioned compatibility discipline and stale-input
  challenge fixtures.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent is performing bounded
mapping, implementation, review, and mechanical publish checks.
