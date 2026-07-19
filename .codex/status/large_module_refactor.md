# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback reconciliation outcome-evidence extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract contact, command, observation, and maneuver success/result projection,
completed fraction, reason, and their reconciliation-only outcome helpers into
`OrbitalDynamics.TimelineFeedback.ReconciliationOutcomeEvidence`. Preserve the
existing report and row assembly facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 4,070 lines, 31 lines ahead
  of Manifest and behind the three larger orchestration-heavy facades.
- The selected fields and helpers form one provider-result/status-to-outcome
  projection responsibility.
- Provider-result normalization and feedback-factor consumers remain with
  their existing owners. Identity, timing, throughput, resource,
  communications, observation-quality, and station-calendar evidence remain
  separate.
- Existing public report APIs and artifact row shapes remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Study.Manifest schema-property ownership extraction, selected in `0105af34`
and implemented in `924833ac`.
`study/manifest.ex` moved from 4,075 to 4,039 lines; the dedicated owner is 44
lines.

Next candidate:
Implement and verify the selected TimelineFeedback reconciliation
outcome-evidence extraction.

Blocked:
No.
