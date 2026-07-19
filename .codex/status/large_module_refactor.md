# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback activity-state artifact extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract compact activity-state artifact assembly, primary-row selection,
status/count summaries, review evidence, and realized trust-boundary
derivation into `OrbitalDynamics.TimelineFeedback.ActivityState`.
Preserve the existing TimelineFeedback public API facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 3,606 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of ContactAllocation,
  RecommendationRiskContext, OrbitalDynamics, Manifest, LinkCapacity,
  StationCalendar, and ResourceProjection.
- The selected family owns one public artifact responsibility: reducing a
  reconciled planned/realized activity pair into its compact activity-state
  contract and review/trust-boundary evidence.
- Reconciliation, realized-input normalization, lifecycle-state derivation,
  operational-feedback aggregation, evidence extraction, and row construction
  remain outside this boundary.
- Existing input validation, reconciliation semantics, artifact fields,
  omission behavior, counts, review rules, and deterministic output remain
  unchanged.

Verification:
Pending.

Behavior/schema changes:
None intended. This is a facade-preserving production ownership extraction.

Last completed slice:
ResourceProjection pressure classification extraction, selected in `bab45b76`
and implemented in `b034086a`.
`resource_projection.ex` moved from 3,629 to 3,447 lines; the dedicated
pressure-classification owner is 192 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
