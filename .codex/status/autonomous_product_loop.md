# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Bind Repair selected candidate-diff metadata to source-report evidence.

Status:
Verified from clean published base `91ced19a`; ready to publish.

Selection evidence:
- The replacement producer selects source candidate-diff rows by source and
  replacement identity, resolves unique or ambiguous matches, and stores the
  exact `CandidateDiffMetadata.metadata/1` projection on the selected activity.
- Current validation replays `semantic_candidate_diff_match` for every ranking
  row but does not compare the selected activity's `repair.candidate_diff`
  projection with the same embedded source-report rows.
- A focused live mutation changed only the selected activity's
  `repair.candidate_diff.invalidated_reason` to `stale_reason`;
  `Schema.validate_artifact/1` still returned `:ok`.

Delivered behavior:
- Reuse the producer's source/replacement identity match, unique-or-ambiguous
  resolution, and `CandidateDiffMetadata.metadata/1` projection for the current
  ranking's selected semantic candidate.
- Require `repair.candidate_diff` to equal that exact embedded source-report
  projection whenever the selected semantic match is replayable.
- Preserve legacy, unmatched, missing-source, and structurally ambiguous
  compatibility while rejecting stale selected metadata at its exact repair
  path.

Verification:
- Focused unique and ambiguous candidate-diff selection: `2 passed`.
- Adjacent candidate-diff handoff and replacement-ranking contracts: `21 passed`.
- Focused stale `invalidated_reason` mutation returned the exact
  `$.activities[0].repair.candidate_diff` error.
- Schema regression: `1077 passed`.
- Campaign planner regression: `1888 passed`.
- Full suite: `5603 passed` (seed `263253`).
- Schema lint: `155` artifacts passed, `0` errors, `0` warnings.
- Canonical Repair and Strategy regeneration passed with stable byte hashes:
  `cc41834e706fd1e04a4c5578032fdf99ceeba949a02fd75fc54c8b70cdc30d8a`
  and `57602722702969da587e2754df84bca1e06e86cc32fa5af7f3f78451b72f9985`.
- `mix format --check-formatted` and `git diff --check` passed.

Level 6 pillar advanced:
Fleet-scale candidate-pool integrity and operator-review evidence fidelity.

Last published slice:
- `91ced19a` Bind Repair selected ranking churn (`5603 passed`; current activity
  churn metadata now matches its selected ranking row).

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
Continue current replacement-ranking repair-handoff audits after selected
candidate-diff metadata is bound.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent performs bounded
mapping, implementation, review, verification, and publish checks.
