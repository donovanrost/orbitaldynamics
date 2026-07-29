# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Bind Repair source candidate scores to their embedded score terms.

Status:
Verified from clean published base `6545b7b8`; ready to publish.

Selection evidence:
- Standalone candidate validation requires a numeric candidate `score` to equal
  the sum of its numeric `score_terms` when both are present.
- Repair validates its source candidate pool structurally and replays ranking
  `candidate_score`, but does not apply that score-explanation invariant to the
  embedded source snapshots.
- A live coordinated mutation changed both selected and source candidate
  `score_terms.contact_value` from 10 to 999 while leaving `score: 10`;
  `Schema.validate_artifact/1` still returned `:ok`.

Delivered behavior:
- Reuse the standalone candidate score-explanation invariant for every embedded
  Repair source candidate when both `score` and `score_terms` are present.
- Preserve compatibility for unscored embedded candidates while rejecting
  additive score-term drift at the exact source-candidate score path.
- Keep six intentionally reweighted candidates in three planner fixtures
  self-explaining by updating their `contact_value` terms with their scores.

Verification:
- Focused replacement-ranking contracts: `13 passed`.
- Adjacent replacement selection and ranking contracts: `20 passed`.
- Affected duplicate, station-calendar, and link-capacity modules: `15 passed`.
- Live post-fix artifact mutation returned the exact
  `$.source_candidate_activities[0].score` error.
- Schema regression: `1076 passed`.
- Campaign planner regression: `1888 passed`.
- Full suite: `5602 passed` (seed `351685`).
- Schema lint: `155` artifacts passed, `0` errors, `0` warnings.
- Canonical Repair and Strategy regeneration passed with stable byte hashes:
  `cc41834e706fd1e04a4c5578032fdf99ceeba949a02fd75fc54c8b70cdc30d8a`
  and `57602722702969da587e2754df84bca1e06e86cc32fa5af7f3f78451b72f9985`.
- `mix format --check-formatted` and `git diff --check` passed.

Level 6 pillar advanced:
Fleet-scale candidate-pool integrity and operator-review evidence fidelity.

Last published slice:
- `6545b7b8` Bind Repair ranking source contexts (`5601 passed`; replayable
  current source contexts now match their exact planned activity projection).

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
Continue replacement-ranking candidate snapshot audits after embedded score
explanations are bound.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent performs bounded
mapping, implementation, review, verification, and publish checks.
