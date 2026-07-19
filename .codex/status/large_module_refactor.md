# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback thermal context extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract declared/planned/actual temperature selection, operating-limit
selection, explicit/derived thermal margin, and thermal evidence projection
into `OrbitalDynamics.TimelineFeedback.ThermalContext`.
Preserve the existing TimelineFeedback public API facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 3,153 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of ContactContention,
  LinkCapacity, Manifest, RecommendationRiskContext, ContactAllocation,
  ResourceProjection, StationCalendar, and OperationalReadiness.
- The selected family is one independent 12-field projection merged into both
  planned and realized feedback rows; it owns temperature alias precedence and
  thermal-margin derivation but not reconciliation or resource aggregation.
- Shared numeric parsing, stable identifier handling, and artifact omission
  remain owned by existing TimelineFeedback helper modules. Planned/realized
  row assembly and every other activity context remain outside this boundary.
- Existing explicit-value precedence, actual/planned/declared fallback,
  one-sided and two-sided derived-margin formulas, atom/string normalization,
  omission behavior, row shape, and deterministic output remain unchanged.

Verification:
Pending implementation.

Behavior/schema changes:
None planned. Existing thermal-value precedence and derivation, feedback-row
shape, artifact contracts, and deterministic output will be preserved.

Last completed slice:
OperationalReadiness timeline-publication context extraction, selected in
`beda0899` and implemented in `18aee27d`.
`operational_readiness.ex` moved from 3,195 to 2,839 lines; the dedicated
timeline-publication context owner is 476 lines.

Next candidate:
Implement and verify the selected thermal-context extraction.

Blocked:
No.
