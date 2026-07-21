# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Reconcile V2 source-filtering score terms.

Status:
Complete; ready to publish.

Selection evidence:
- V2 contact-filter, resource-filter, and candidate-rejection penalties are
  produced from embedded source reports but are not recomputed by the contract.
- Coordinated edits to these terms, the total, and score-term report can remain
  internally valid while understating suppressed or rejected candidates.
- Producer formulas are deterministic and have positive planner fixtures for all
  three report families.

Intended behavior:
- Extract shared source-filter counts used by producer and validator: suppressed
  rows/count fallback for contact/resource reports and rejected rows/IDs/count
  fallback for candidate-rejection reports.
- Recompute each present penalty from its shared count and `risk_weight`.
- Preserve optional legacy terms, absent/nominal reports, zero risk weight,
  numeric-string/default policy handling, malformed-report safety, and checked
  V2 compatibility.
- Add coordinated-tamper, positive planner, nominal/optional/default/zero,
  fallback, and malformed-report coverage; document the guarantees.

Level 6 pillar advanced:
Explainable V2 candidate-filtering terms backed by embedded source evidence.

Last published slice:
- `715a7325` Reconcile V2 readiness score terms (`3719 passed`).

Likely files:
- shared repair source-filter pressure classifier
- V2 campaign-repair score runtime contract
- focused score contract tests
- V2 capability and roadmap docs

Verification:
- Focused score/source-filter planner tests: `19 passed`.
- Campaign-repair schema fixtures: `23 passed`.
- Schema suite plus schema-lint task tests: `401 passed`.
- Campaign-planner suite: `759 passed`.
- Full suite: `3721 passed`.
- `mix format --check-formatted`, `mix compile --warnings-as-errors`, and
  `git diff --check` passed.
- Runtime-only reconciliation required no generated schema changes.

Review:
- Contact/resource suppression counts preserve row-list precedence and numeric
  declared-count truncation without inventing candidate deduplication.
- Candidate rejection preserves row precedence, missing-status-as-rejected,
  exact nonblank-ID fallback, and positive numeric-count fallback semantics;
  the producer's stringify callback seam remains intact.
- Malformed non-map rejection rows safely remain neutral for derived scoring
  while structural report validators own their shape errors.
- Policy values retain producer-equivalent numeric-string parsing, zero weights,
  and missing-key defaults; all three terms remain optional for older V2 maps.
- Positive planner artifacts and nominal fixtures remain valid, while coordinated
  term, total, and score-report edits no longer mask any of the three mismatches.

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
