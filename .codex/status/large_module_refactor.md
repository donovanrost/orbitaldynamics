# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback execution-uncertainty extraction.

Status:
Completed and pushed in `1c8213e6`.

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
- Strict warnings-as-errors compile passed across 3,874 files.
- Focused TimelineFeedback coverage passed: 73 tests.
- Adjacent operator-review, contact-feedback-contract, and realized-activity
  feedback integration coverage passed: 10 tests.
- Exact old/new public output comparison against `194959c0` passed for 7
  realized-activity normalization cases and one reconciliation-precedence
  artifact.
- Runtime xref found the new owner referenced only by the `TimelineFeedback`
  facade; static single-ownership review and `git diff --check` passed.
- Bounded review restored exact `Map.fetch` fallback semantics for false-valued
  explicit delta-v input before the final focused rerun.
- `timeline_feedback.ex` moved from 5,173 to 5,023 lines; the dedicated owner
  is 234 lines.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback execution-uncertainty extraction, selected in `194959c0` and
implemented in `1c8213e6`. `timeline_feedback.ex` moved from 5,173 to 5,023
lines; the dedicated owner is 234 lines.

Next candidate:
Re-inventory the remaining TimelineFeedback normalization and reconciliation
families after execution uncertainty has one production owner.

Blocked:
No.
