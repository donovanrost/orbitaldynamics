# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Reconcile V2 schedule churn and movement score terms.

Status:
Complete; ready to publish.

Selection evidence:
- V2 `schedule_churn_penalty` and `schedule_move_penalty` are numeric and total-
  consistent but are not recomputed from repair deltas, activity churn seconds,
  and the embedded scoring policy.
- Coordinated edits to either term, the total, and score-term report can therefore
  remain internally valid while misrepresenting schedule disruption.
- Producer formulas are deterministic and all inputs are already embedded in the
  repair artifact.

Intended behavior:
- Recompute a present churn penalty from moved/replaced/canceled/suppressed delta
  count and `schedule_churn_cost_weight`.
- Recompute a present move penalty from repaired activity `schedule_churn_s`
  totals and `schedule_move_cost_weight`.
- Preserve optional legacy term maps, numeric-string/default policy handling,
  zero movement, extensible delta actions, and checked V2 compatibility.
- Add arithmetic-consistent tamper, action filtering, zero/default, optional-term,
  and checked-fixture coverage; document the executable guarantees.

Level 6 pillar advanced:
Explainable V2 schedule-disruption terms backed by repair evidence and policy.

Last published slice:
- `d1418ed7` Reconcile V2 aggregate activity score (`3711 passed`).

Likely files:
- V2 campaign-repair score runtime contract
- focused score contract tests
- V2 capability and roadmap docs

Verification:
- Focused score/source-handoff contract tests: `9 passed`.
- Campaign-repair schema fixtures: `15 passed`.
- Schema suite plus schema-lint task tests: `393 passed`.
- Campaign-planner suite: `759 passed`.
- Full suite: `3713 passed`.
- `mix format --check-formatted`, `mix compile --warnings-as-errors`, and
  `git diff --check` passed.
- Runtime-only reconciliation required no generated schema changes.

Review:
- Churn counts only moved/replaced/canceled/suppressed delta actions; unknown
  future actions remain neutral until deliberately classified.
- Movement cost sums numeric repaired-activity churn seconds and safely treats
  absent, nonnumeric, or malformed surrounding repair evidence as zero while
  structural validators report invalid shapes.
- Policy values use producer-equivalent numeric-string parsing and missing-key
  defaults; both terms remain optional for compatible older V2 score maps.
- Coordinated term, total, and score-report edits no longer mask either mismatch.

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
