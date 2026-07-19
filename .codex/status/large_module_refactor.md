# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback reconciliation observation-evidence extraction.

Status:
Completed and pushed in `180de1a0`.

Selected boundary:
Extract planned/realized pointing, attitude, lighting, image-quality, and
thermal evidence reconciliation into
`OrbitalDynamics.TimelineFeedback.ReconciliationObservationEvidence`. Preserve
the existing report and row assembly facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 4,376 lines, immediately
  behind MissionPlan.Activity and ahead of Study.Manifest.
- The selected reconciliation-row fields form a contiguous observation-
  evidence responsibility and depend only on planned and realized row maps.
- Identity matching, command authority, link quality, resource state,
  throughput, execution uncertainty, operational-feedback exclusion, and
  report aggregation remain in the facade.
- Existing public report APIs and artifact row shapes remain unchanged.

Verification:
- Strict warnings-as-errors compile passed across 3,892 files.
- Focused `timeline_feedback_test.exs` passed under warnings-as-errors: 73
  tests.
- Adjacent operator-review timeline-feedback, Cadence import, and contact-
  feedback schema coverage passed under warnings-as-errors: 79 tests.
- Exact public old/new comparison against `df6f88b8` passed 5 reconciliation
  reports covering matched, mismatched, planned-only, realized-only, and mixed
  rows with valid divergent values across every moved evidence family.
- `mix xref callers
  OrbitalDynamics.TimelineFeedback.ReconciliationObservationEvidence` reports
  only the TimelineFeedback facade as a runtime caller.
- Static ownership review confirms reconciliation pointing, attitude,
  lighting, image-quality, and thermal evidence assembly lives in the new
  owner; source normalization remains in the facade.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback reconciliation observation-evidence extraction, selected in
`df6f88b8` and implemented in `180de1a0`. `timeline_feedback.ex` moved from
4,376 to 4,293 lines; the dedicated owner is 117 lines.

Next candidate:
Re-rank the remaining large modules and select the next cohesive,
facade-preserving responsibility boundary.

Blocked:
No.
