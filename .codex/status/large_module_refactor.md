# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness unavailable-resource summary extraction.

Status:
Completed and pushed in `6686d3a4`.

Selected boundary:
Extract unavailable-resource quality-gate summary construction and its
row-aggregation helpers into
`OrbitalDynamics.OperationalReadiness.QualityGateUnavailableResourceSummary`.
Preserve all OperationalReadiness and downstream public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `operational_readiness.ex` at 1,063 lines, the
  largest ordinary eligible facade.
- Operator-training, schema-validation, import-readiness, and general quality
  summaries already have focused owners, while unavailable-resource summary
  construction and its row aggregation remain inline.
- The selected code has one responsibility: aggregate resource-availability
  rows into reason, station, blocking, contact, status, and routing summaries.
- Quality-gate report construction, row projection, readiness evidence
  construction, and all gates remain outside the boundary.
- Exact artifact fields, positive-count filtering, reason classification,
  stable ID normalization, count merging, status routing, assumptions,
  model limits, nil compaction, public output, and error behavior must remain
  unchanged.

Implementation:
- Added
  `OrbitalDynamics.OperationalReadiness.QualityGateUnavailableResourceSummary`
  as the focused owner of unavailable-resource summary construction, positive
  count merging, reason classification, blocked-contact aggregation, routing,
  stable IDs, and nil compaction.
- Preserved all public OperationalReadiness facades through the summary
  builder.
- Removed facade helpers that became dead after their only summary consumer
  moved; report construction, row projection, evidence construction, and all
  gates remain outside the extraction.
- `operational_readiness.ex` moved from 1,063 to 903 lines; the dedicated
  QualityGateUnavailableResourceSummary owner is 213 lines.

Verification:
- Strict focused baseline: 31 tests passed with warnings treated as errors.
- Exact old/new public parity: four results passed, covering multi-row count
  merging, reason classification, blocked-contact and status routing, stable
  row/gate IDs, empty output, atom-key normalization, nil compaction, and the
  root facade.
- Post-change core, operator-review, schema, and fixture checks: 51 tests
  passed with warnings treated as errors.
- Static ownership and xref checks passed; only the facade calls the extracted
  owner at runtime.
- Forced warning-clean test compile passed across 4,038 files.
- Focused formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
OperationalReadiness unavailable-resource summary extraction, selected in
`98f6fe39` and implemented in `6686d3a4`.
`operational_readiness.ex` moved from 1,063 to 903 lines; the dedicated
QualityGateUnavailableResourceSummary owner is 213 lines.

Next candidate:
After this slice, re-rank the live checkout. RecommendationRiskContext is the
next largest ordinary eligible facade.

Blocked:
No.
