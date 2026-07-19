# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness quality-gate operator-training summary extraction.

Status:
Completed and pushed in `cca255af`.

Selected boundary:
Extract operator-training quality-gate row selection, requirement aggregation,
role/training/certification/qualification routing, status/classification ID
maps, review-state derivation, and summary assembly into
`OrbitalDynamics.OperationalReadiness.QualityGateOperatorTrainingSummary`.
Preserve the public OperationalReadiness facade and all input-shape/idempotent
clauses.

Selection evidence:
- Live re-ranking places `operational_readiness.ex` at 2,839 lines, fifth
  behind Schema, Timeline, MissionPlan.Activity, and the intentionally public
  `OrbitalDynamics` facade, and ahead of TimelineFeedback, ContactContention,
  LinkCapacity, StationCalendar, RecommendationRiskContext, and
  ResourceProjection.
- The selected builder spans lines 779-845, with exclusive row/requirement
  selectors at lines 1,120-1,129. It owns operator-training row selection,
  positive requirement count aggregation, required role/training/certification/
  qualification routing, gate row and gate identity maps, review-state
  derivation, assumptions, and model limits.
- Small generic summary operations needed by the owner—row extraction,
  positive map totals, scalar/list normalization, stable IDs, grouped IDs, and
  nil compaction—remain exact local support rather than expanding the boundary
  into unrelated quality-gate summaries.
- Readiness report construction, generic and other specialized quality-gate
  summaries, gate evidence collection, Cadence/review-package routing,
  publication context, policy/resource/schema/import gates, and public
  contracts remain outside this boundary.
- Existing stringification, row filtering, positive-count semantics, stable
  sorting, grouped identity maps, omission of nil summary values, idempotent
  input handling, and exact errors must remain unchanged.

Verification:
- Strict warning-clean compile passed across 3,951 files:
  `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force --warnings-as-errors`.
- Focused operator-training quality-gate assertion passed: 1 test.
- Adjacent full operational-readiness, strategy quality-gate pressure,
  candidate-refresh replay, Cadence wrapped-summary, and validation-fixture
  regression bundle passed: 55 tests.
- Exact old/new parity passed 6 comparisons from selection commit `303a6a96`
  with `/tmp/readiness_operator_training_summary_compare.exs`, covering rich
  multi-row training evidence, atom-key normalization, empty reports,
  non-training/malformed row filtering, stable grouped IDs and duplicate
  removal, and invalid-artifact errors.
- `mix xref callers
  OrbitalDynamics.OperationalReadiness.QualityGateOperatorTrainingSummary`
  reports only the OperationalReadiness facade.
- The owner has no compile-connected expansion beyond itself.
- Focused formatting, `git diff --check`, removed-selector static checks, and
  final facade/owner review passed.

Behavior/schema changes:
None. The public OperationalReadiness facade, operator-training summary
contract, positive requirement counts, stable ID maps, row filtering,
compaction, and exact errors are unchanged.

Last completed slice:
OperationalReadiness quality-gate operator-training summary extraction,
selected in `303a6a96` and implemented in `cca255af`.
`operational_readiness.ex` moved from 2,839 to 2,766 lines; the dedicated
operator-training summary owner is 156 lines.

Next candidate:
Re-rank the live largest-module inventory and select the next cohesive,
facade-preserving ownership boundary.

Blocked:
No.
