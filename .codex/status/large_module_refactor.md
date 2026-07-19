# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback success-factor normalization extraction.

Status:
Selected; implementation has not started.

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
Pending: focused timeline-feedback baseline, exact old/new public artifact
outputs, strict compile, broader timeline-feedback tests, static single
ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback provider-result normalization extraction, selected in
`d9366691` and implemented in `19b422d6`. `timeline_feedback.ex` moved from
5,463 to 5,343 lines; the dedicated owner is 133 lines.

Next candidate:
Re-inventory remaining TimelineFeedback execution-uncertainty and
normalization families after success-factor normalization has one production
owner.

Blocked:
No.
