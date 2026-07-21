# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Reconcile V2 score-term report identity metadata.

Status:
Complete; ready to publish.

Selection evidence:
- V2 score-term validation pins row values, timeline score, rank, selection,
  unique term coverage, and source, but not repair-specific identity metadata.
- An internally valid report can still use another allowed report model, drift
  its embedded policy/source assumption, reorder rows, or rewrite row scenario
  and stable IDs independently of the repair source plan.
- Producer identities and row ordering are deterministic from source plan and
  enclosing score-term keys.

Intended behavior:
- Require a present score-term report to use the repair model, exact embedded
  policy and source assumption, and deterministic sorted term order.
- Pin every row scenario ID to `source_plan_id` and its stable row ID to the
  producer's `score_term:<scenario>:1:<term>` identity.
- Preserve the report as optional and malformed-shape safe.
- Add checked-fixture, model/policy/source, row-order, scenario/ID tamper, and
  optional-report coverage; document the executable guarantees.

Level 6 pillar advanced:
Replayable V2 score rows with deterministic repair identity and policy metadata.

Last published slice:
- `a9f7c489` Reconcile V2 objective tradeoff report (`3727 passed`).

Likely files:
- V2 campaign-repair score runtime contract
- focused score-term report tests
- V2 capability and roadmap docs

Verification:
- Focused score-contract and repair-planner tests: `20 passed`.
- Campaign-repair schema fixtures: `30 passed`.
- Schema suite plus schema-lint task tests: `408 passed`.
- Campaign-planner suite: `759 passed`.
- Full suite: `3728 passed`.
- `mix format --check-formatted`, `mix compile --warnings-as-errors`, and
  `git diff --check` passed.
- Runtime-only reconciliation required no generated schema changes.

Review:
- Cross-validation now requires the repair-specific score-term model and exact
  embedded score-term source and enclosing scoring policy.
- Rows must cover the enclosing score-term keys once in sorted producer order;
  each row scenario is pinned to `source_plan_id` and each stable ID is rebuilt
  from that scenario, rank one, and the row's term key.
- Existing value, timeline-score, rank, selection, and source reconciliation
  remains intact, so coordinated identity edits cannot mask score drift.
- The report remains optional for compatible older V2 artifacts, malformed
  shapes remain owned by generic validators without raising here, and checked
  fixtures plus real planner output remain valid.

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
