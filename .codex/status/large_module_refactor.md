# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback reconciliation plan-evidence extraction.

Status:
Completed and pushed in `fddf4f52`.

Selected boundary:
Extract planned dependency/exclusivity, Cadence import, operator-action,
timeline-integrity, and invalid-input evidence projection into
`OrbitalDynamics.TimelineFeedback.ReconciliationPlanEvidence`. Preserve the
existing report and row assembly facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 3,894 lines, ahead of
  Manifest and ContactAllocation and behind the three larger
  orchestration-heavy facades.
- The selected 27 output fields form one planned-governance evidence
  projection and depend only on the normalized planned row.
- Matching, lifecycle/protection decisions, source contexts, realized
  evidence, and report aggregation remain in the facade or their current
  owners.
- Four operator-action output names are intentional projections and remain
  explicitly mapped in the new owner.
- Existing public report APIs and artifact row shapes remain unchanged.

Verification:
- Strict test-environment compile passed with warnings as errors across 3,904
  files.
- Focused TimelineFeedback coverage passed: 73 tests.
- Adjacent operator-review, Cadence import, and contact-feedback contract
  coverage passed: 79 tests.
- Exact public old/new comparison against selection commit `54aad1a5` passed
  for six reports with asserted dependency, exclusivity, and operator action.
- `mix xref callers` reports only the TimelineFeedback facade as a runtime
  caller of the extracted owner.
- Static ownership checks confirm planned governance projection lives in the
  dedicated owner while normalization and aggregation remain in the facade.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback reconciliation plan-evidence extraction, selected in
`54aad1a5` and implemented in `fddf4f52`.
`timeline_feedback.ex` moved from 3,894 to 3,862 lines; the dedicated owner is
45 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
