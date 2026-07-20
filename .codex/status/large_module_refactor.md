# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema operational-readiness capability-context extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract the OperationalReadiness capability accessor and model-limit
projection into
`OrbitalDynamics.Schema.OperationalReadinessCapabilityContext`.
Route the Schema facade's ten direct capability dependencies through the
focused accessor. Preserve
`OperationalReadinessValidation.operational_readiness_model_limits/0` as a
delegating API to the new owner.
Keep all consuming schema construction, property dispatch, and validation
ownership in their current modules.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,186 lines.
- OperationalReadiness capabilities are fetched directly at ten Schema facade
  call sites spanning property dispatch and readiness-aware row schemas, plus
  once in OperationalReadinessValidation for model limits.
- The selected code has one responsibility: expose schema-facing
  OperationalReadiness capability context to otherwise independent consumers.
- The focused accessor and model-limit projection replace repeated module
  coupling while preserving callback timing, per-call capability evaluation,
  and the existing validation API. All property-dispatch, row-schema, and
  validation consumers remain in their current owners.
- Exact atom-to-string conversion, capability values and ordering, generated
  JSON Schema, validation results, and checked-in exports must remain
  unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema operator-review capability-context extraction, selected in `8b3c2daf`
and implemented in `236d08f0`.
`schema.ex` moved from 6,184 to 6,186 lines; the dedicated
OperatorReviewCapabilityContext owner is 21 lines and all five direct
OperatorReview capability dependencies moved behind it.

Next candidate:
Re-rank the remaining Schema capability/model-limit responsibility clusters.

Blocked:
No.
