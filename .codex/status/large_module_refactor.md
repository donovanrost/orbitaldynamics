# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback success-factor normalization extraction.

Status:
Completed and pushed in `da8f5be3`.

Selected boundary:
Extract observation, contact, and command success-factor selection, source
attribution, and numeric validation into
`OrbitalDynamics.TimelineFeedback.SuccessFactor`. Preserve the existing
private helper seams used by `TimelineFeedback`; pass command-contact
directions and provider-result interpretation into the dedicated owner.

Selection evidence:
- Live re-ranking shows `timeline_feedback.ex` remains the second-largest
  production module at 5,343 lines after `schema.ex` at 6,764 lines.
- The selected 4,945-5,155 helper family owns one scalar feedback concern used
  when building planned, realized, and realized-activity-context rows.
- The owner can also centralize the unit-interval and nonnegative-number status
  checks already used by realized-input sanitization, without moving row
  assembly or reconciliation policy out of the facade.
- Provider-result normalization remains in its existing dedicated owner;
  success-factor selection consumes its public outcome through a narrow
  dependency rather than duplicating token classification.

Verification:
- Strict warnings-as-errors compile passed across 3,873 files.
- Focused TimelineFeedback coverage passed: 73 tests.
- Adjacent operator-review, contact-feedback-contract, and realized-activity
  feedback integration coverage passed: 10 tests.
- Exact old/new public output comparison against `8a40121e` passed for 10
  realized-activity normalization cases and one reconciliation artifact.
- Runtime xref found the new owner referenced only by the `TimelineFeedback`
  facade; static single-ownership review and `git diff --check` passed.
- Bounded review retained nil-on-malformed nested path behavior before the
  final compile and focused rerun.
- `timeline_feedback.ex` moved from 5,343 to 5,173 lines; the dedicated owner
  is 261 lines.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback success-factor normalization extraction, selected in
`8a40121e` and implemented in `da8f5be3`. `timeline_feedback.ex` moved from
5,343 to 5,173 lines; the dedicated owner is 261 lines.

Next candidate:
Re-inventory remaining TimelineFeedback execution-uncertainty and
normalization families after success-factor normalization has one production
owner.

Blocked:
No.
