# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback reconciliation lifecycle-evidence extraction.

Status:
Completed and pushed in `ea3a4941`.

Selected boundary:
Extract row lifecycle status, planned/realized type and status, public status
transition, protection decision, source activities, and activity contexts into
`OrbitalDynamics.TimelineFeedback.ReconciliationLifecycleEvidence`. Preserve
the existing report and row assembly facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 3,842 lines, six lines ahead
  of Manifest and ahead of ContactAllocation, behind the three larger
  orchestration-heavy facades.
- The selected fields and five helper families form one planned-versus-realized
  lifecycle/protection evidence responsibility.
- Status transition and protection continue to delegate to the public Timeline
  owner; configuration and algorithms are not duplicated.
- Matching metadata, ingress, plan, resource, timing, outcome, and aggregation
  responsibilities remain separate.
- Existing public report APIs and artifact row shapes remain unchanged.

Verification:
- Strict test-environment compile passed with warnings as errors across 3,906
  files.
- Focused TimelineFeedback coverage passed: 73 tests.
- Adjacent operator-review, Cadence import, and contact-feedback contract
  coverage passed: 79 tests.
- Exact public old/new comparison against selection commit `f517ed33` passed
  for six reports with asserted lifecycle status, transition, protection,
  source activity, and activity-context evidence.
- `mix xref callers` reports only the TimelineFeedback facade as a runtime
  caller of the extracted owner.
- Static ownership checks confirm lifecycle projection and its helper families
  live in the dedicated owner while matching and aggregation remain in the
  facade.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback reconciliation lifecycle-evidence extraction, selected in
`f517ed33` and implemented in `ea3a4941`.
`timeline_feedback.ex` moved from 3,842 to 3,776 lines; the dedicated owner is
83 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
