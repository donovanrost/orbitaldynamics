# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness timeline-publication context extraction.

Status:
Selected; implementation pending.

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
Pending implementation.

Behavior/schema changes:
None planned. Existing publication evidence precedence and aggregation,
readiness shape, schema contracts, and deterministic output will be preserved.

Last completed slice:
Manifest ground-station catalog input extraction, selected in `03d2f023` and
implemented in `04338497`.
`study/manifest.ex` moved from 3,234 to 3,108 lines; the dedicated
ground-station catalog owner is 146 lines.

Next candidate:
Implement and verify the selected timeline-publication context extraction.

Blocked:
No.
