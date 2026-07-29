# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Bind Repair activity churn to the selected replacement-ranking row.

Status:
Verified from clean published base `243a30e7`; ready to publish.

Selection evidence:
- The replacement producer derives both `repair.schedule_churn_s` and the
  selected ranking row's `schedule_churn_s` from the same source-to-candidate
  start-time delta.
- Row validation replays its churn from embedded source evidence, while repair
  score validation only consumes the activity-level value through a weighted
  aggregate.
- With `schedule_move_cost_weight: 0`, a live artifact carried 400 seconds in
  both producer fields; changing only `repair.schedule_churn_s` to 999 still
  returned `:ok` from `Schema.validate_artifact/1`.

Delivered behavior:
- Require each current replacement ranking's activity-level
  `repair.schedule_churn_s` to equal the only selected row's replayed
  `schedule_churn_s`.
- Preserve legacy ranking compatibility and defer malformed or ambiguous rows to
  their existing structural diagnostics.
- Reject focused activity-level churn drift at its exact repair metadata path.

Verification:
- Focused replacement-ranking contracts: `14 passed`.
- Adjacent replacement selection and ranking contracts: `21 passed`.
- Live zero-move-weight mutation returned the exact
  `$.activities[0].repair.schedule_churn_s` error.
- Schema regression: `1077 passed`.
- Campaign planner regression: `1888 passed`.
- Full suite: `5603 passed` (seed `839321`).
- Schema lint: `155` artifacts passed, `0` errors, `0` warnings.
- Canonical Repair and Strategy regeneration passed with stable byte hashes:
  `cc41834e706fd1e04a4c5578032fdf99ceeba949a02fd75fc54c8b70cdc30d8a`
  and `57602722702969da587e2754df84bca1e06e86cc32fa5af7f3f78451b72f9985`.
- `mix format --check-formatted` and `git diff --check` passed.

Level 6 pillar advanced:
Fleet-scale candidate-pool integrity and operator-review evidence fidelity.

Last published slice:
- `243a30e7` Bind Repair source candidate score terms (`5602 passed`; scored
  embedded candidates now remain self-explaining while unscored compatibility
  is preserved).

Remaining maturity gaps:
- Audit remaining generated and source handoffs where their complete producer
  eligibility rules can be reproduced.
- Preserve explicit report-optional compatibility where downstream handoffs are
  independently derived rather than owned by the optional report.
- Continue fleet-scale station/allocation decisions only from authoritative,
  candidate-identified evidence while preserving provider/Cadence boundaries.
- Bind additional ranking membership predicates only where the full producer
  eligibility decision can be replayed without ambiguity.
- Continue broader schema/versioned compatibility discipline and stale-input
  challenge fixtures.

Next candidate:
Continue current replacement-ranking repair-handoff audits after selected churn
is bound.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent performs bounded
mapping, implementation, review, verification, and publish checks.
