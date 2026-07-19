# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback execution-uncertainty extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract maneuver delta-v normalization, execution-uncertainty declaration and
field normalization, row-context precedence, and vector calculations into
`OrbitalDynamics.TimelineFeedback.ExecutionUncertainty`. Preserve the existing
private helper seams used by row construction and reconciliation.

Selection evidence:
- Live re-ranking shows `timeline_feedback.ex` remains a top-three production
  hotspot at 5,173 lines, behind `schema.ex` and `mission_plan/activity.ex`.
- The selected 4,774-4,943 helper family is contiguous and owns one artifact
  concern consumed by planned rows, realized rows, reconciliation, and
  operational-feedback summaries.
- Execution-uncertainty precedence and vector normalization have no dependency
  on report assembly, operator-review packaging, or schema policy.
- Existing facade seams for context, reconciliation context, delta-v,
  triplets, norms, and deltas allow a mechanical delegation boundary.

Verification:
Pending: focused timeline-feedback baseline, exact old/new public artifact
outputs, strict compile, broader timeline-feedback tests, static single
ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback success-factor normalization extraction, selected in
`8a40121e` and implemented in `da8f5be3`. `timeline_feedback.ex` moved from
5,343 to 5,173 lines; the dedicated owner is 261 lines.

Next candidate:
Re-inventory the remaining TimelineFeedback normalization and reconciliation
families after execution uncertainty has one production owner.

Blocked:
No.
