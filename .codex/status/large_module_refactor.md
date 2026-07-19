# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness timeline-publication context extraction.

Status:
Completed and pushed.

Selected boundary:
Extract timeline-publication source discovery, context normalization,
duplicate-publication merging, count/list aggregation, row-summary reduction,
and evidence-map projection into
`OrbitalDynamics.OperationalReadiness.TimelinePublicationContext`.
Preserve the existing OperationalReadiness public API facade.

Selection evidence:
- Live re-ranking places `operational_readiness.ex` at 3,195 lines, fourth
  behind Schema, Timeline, and MissionPlan.Activity and ahead of
  TimelineFeedback, ContactContention, LinkCapacity, Manifest,
  RecommendationRiskContext, ContactAllocation, ResourceProjection, and
  StationCalendar.
- The selected family is one contiguous 21-field evidence reducer reached from
  readiness evidence assembly, quality-gate import-readiness summarization,
  and Cadence-import gate context.
- Gate evaluation, report and summary assembly, resource availability,
  operator training, schema validation, adapter boundary, policy
  classification, and import-classification decisions remain outside this
  boundary.
- Existing recursive source precedence, publication-ID dedupe, first-nonempty
  scalar preference, max-per-publication counts, summed cross-publication
  counts, sorted unique identifiers, empty-value omission, and deterministic
  output remain unchanged.

Verification:
- Focused baseline before implementation:
  `test/orbital_dynamics/operational_readiness_test.exs` passed 31 tests.
- Strict compilation after implementation:
  `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force --warnings-as-errors`
  compiled 3,938 files successfully.
- Focused regression:
  `test/orbital_dynamics/operational_readiness_test.exs` passed 31 tests.
- Adjacent regressions:
  `test/orbital_dynamics/campaign_planner/strategy_timeline_publication_source_report_test.exs`
  passed 2 tests,
  `test/orbital_dynamics/validation/operational_readiness_fixture_test.exs`
  passed 5 tests, and
  `test/orbital_dynamics/operator_review/operational_readiness_test.exs`
  passed 3 tests.
- Exact old/new comparison against selection commit `beda0899` exposed all
  three selected private entry paths and compared five raw-evidence builds,
  three row reductions, and two evidence-map projections; all 10 outputs
  matched exactly.
- The exact inputs covered empty, direct, wrapped, duplicate-ID, anonymous,
  pre-summarized, invalid-row, scalar-normalization, max-count, summed-count,
  list/map merge, and unrelated-field omission behavior.
- `git diff --check` passed.
- `mix xref callers
  OrbitalDynamics.OperationalReadiness.TimelinePublicationContext` reports
  only the OperationalReadiness facade as a runtime caller; compile-connected
  xref reports no unexpected coupling.
- Static review confirmed the owner exposes only `build/3`, `from_rows/1`, and
  `from_evidence/1`; gate evaluation, other evidence families, report assembly,
  and import classification remain outside the boundary.

Behavior/schema changes:
None. Existing publication evidence precedence and aggregation, readiness
shape, schema contracts, and deterministic output are preserved.

Last completed slice:
OperationalReadiness timeline-publication context extraction, selected in
`beda0899` and implemented in `18aee27d`.
`operational_readiness.ex` moved from 3,195 to 2,839 lines; the dedicated
timeline-publication context owner is 476 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
