# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback reconciliation timing-evidence extraction.

Status:
Completed and pushed in `c8ec267e`.

Selected boundary:
Extract planned/actual timing fields, start/end deltas, maximum absolute
variance, threshold projection, and timing status into
`OrbitalDynamics.TimelineFeedback.ReconciliationTimingEvidence`. Preserve the
existing report and row assembly facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 4,122 lines, behind Timeline
  and MissionPlan.Activity but ahead of the remaining Manifest facade.
- The selected reconciliation-row fields form one planned-versus-realized
  timing-variance responsibility and depend only on the planned and realized
  row maps plus the public reconciliation threshold option.
- Generic delta math remains in the facade for throughput and maneuver
  comparisons. Identity, observation, communications, resource and
  station-calendar evidence, success outcomes, execution uncertainty,
  operational-feedback exclusion, and report aggregation remain with their
  current owners.
- Existing public report APIs and artifact row shapes remain unchanged.

Verification:
- Strict test-environment compile passed with warnings as errors across 3,898
  files.
- Focused TimelineFeedback coverage passed: 73 tests.
- Adjacent operator-review, Cadence import, and contact-feedback contract
  coverage passed: 79 tests.
- Exact public old/new comparison against selection commit `90ff1df4` passed
  for five reports covering matched, mismatched, planned-only, realized-only,
  and mixed rows with nonzero timing deltas and threshold evaluation.
- `mix xref callers` reports only the TimelineFeedback facade as a runtime
  caller of the extracted owner.
- Static ownership checks confirm timing calculation and status helpers live
  in the dedicated owner while generic delta math remains in the facade.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback reconciliation timing-evidence extraction, selected in
`90ff1df4` and implemented in `c8ec267e`.
`timeline_feedback.ex` moved from 4,122 to 4,099 lines; the dedicated owner is
42 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
