# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback maneuver reconciliation ownership extraction.

Status:
Selected; implementation not started.

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
Pending.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback success-factor reconciliation ownership extraction, selected
in `c3205948` and implemented in `cfb4be1d`.
`timeline_feedback.ex` moved from 3,950 to 3,917 lines; the SuccessFactor owner
moved from 261 to 300 lines.

Next candidate:
Implement and verify the selected TimelineFeedback maneuver reconciliation
ownership extraction.

Blocked:
No.
