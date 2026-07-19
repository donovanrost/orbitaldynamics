# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback reconciliation outcome-evidence extraction.

Status:
Completed and pushed in `64be0fd0`.

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
- Strict test-environment compile passed with warnings as errors across 3,900
  files.
- Focused TimelineFeedback coverage passed: 73 tests.
- Adjacent operator-review, Cadence import, and contact-feedback contract
  coverage passed: 79 tests.
- Exact public old/new comparison against selection commit `32b15d88` passed
  for five reports covering matched, mismatched, planned-only, realized-only,
  and mixed rows with successful and failed provider outcomes.
- `mix xref callers` reports only the TimelineFeedback facade as a runtime
  caller of the extracted owner.
- Static ownership checks confirm reconciliation outcome projection lives in
  the dedicated owner while provider normalization and feedback consumers
  remain in the facade.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback reconciliation outcome-evidence extraction, selected in
`32b15d88` and implemented in `64be0fd0`.
`timeline_feedback.ex` moved from 4,070 to 3,950 lines; the dedicated owner is
215 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
