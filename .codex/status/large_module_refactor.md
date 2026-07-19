# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback maneuver reconciliation ownership extraction.

Status:
Completed and pushed in `05c056c2`.

Selected boundary:
Move planned/realized maneuver delta-v vectors and magnitudes, vector/scalar
deltas, and match status into the existing
`OrbitalDynamics.TimelineFeedback.ExecutionUncertainty` owner. Preserve the
existing report and row assembly facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 3,917 lines, ahead of
  Manifest and ContactAllocation and behind the three larger
  orchestration-heavy facades.
- The selected fields and helpers form one planned-versus-realized maneuver
  execution comparison responsibility.
- Vector normalization and delta math already live in the selected owner; this
  extension eliminates the facade's now-single-purpose vector and match
  wrappers without duplicating math.
- Generic scalar delta remains in the facade for thermal comparison. Outcome,
  factor, timing, throughput, identity, and aggregation remain separate.
- Existing public report APIs and artifact row shapes remain unchanged.

Verification:
- Strict test-environment compile passed with warnings as errors across 3,903
  files.
- Focused TimelineFeedback coverage passed: 73 tests.
- Adjacent operator-review, Cadence import, and contact-feedback contract
  coverage passed: 79 tests.
- Exact public old/new comparison against selection commit `a294e7d0` passed
  for six reports, including an asserted delta-v mismatch row.
- `mix xref callers` reports the TimelineFeedback facade and the existing
  Throughput owner as runtime callers of ExecutionUncertainty.
- Static ownership checks confirm maneuver comparison and match status live in
  ExecutionUncertainty while generic scalar delta remains in the facade.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback maneuver reconciliation ownership extraction, selected in
`a294e7d0` and implemented in `05c056c2`.
`timeline_feedback.ex` moved from 3,917 to 3,894 lines; the
ExecutionUncertainty owner moved from 220 to 251 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
