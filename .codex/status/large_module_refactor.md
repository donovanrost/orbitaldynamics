# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema operational-readiness capability-context extraction.

Status:
Completed and pushed.

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
Added `OrbitalDynamics.Schema.OperationalReadinessCapabilityContext`, which
now owns the OperationalReadiness capability accessor and model-limit
projection. The Schema facade routes all ten former direct dependencies
through the focused accessor, while
`OperationalReadinessValidation.operational_readiness_model_limits/0`
remains available as a delegation to the new owner.
`schema.ex` moved from 6,186 to 6,189 lines due to the explicit import; the
validation owner moved from 234 to 232 lines and the dedicated context is 13
lines.

Verification:
- Strict focused operational/readiness/Cadence-import/campaign-repair/
  candidate-refresh/validation baseline before extraction: 21 passed.
- The same strict focused suite after extraction: 21 passed.
- Strict full schema-export task plus adjacent JSON Schema export,
  operator-review, Cadence-row, and fixture-visibility coverage completed all
  19 cases successfully; this combination suppressed ExUnit's final summary
  line in two repeated runs.
- `mix xref callers
  OrbitalDynamics.Schema.OperationalReadinessCapabilityContext` reports only
  `schema.ex (export)` and `operational_readiness_validation.ex (runtime)`.
- `git diff --check` passed; no checked-in schema export changed.
- Strict forced compile passed across 4,061 files.
- Implementation commit `c7024a68` pushed to `main`.

Behavior/schema changes:
None. Public and internal validation facades, callback timing, per-call
capability evaluation, model-limit conversion, generated JSON Schema,
validation behavior, and checked-in exports remain unchanged.

Last completed slice:
Schema operational-readiness capability-context extraction, selected in
`37828a28` and implemented in `c7024a68`.
`schema.ex` moved from 6,186 to 6,189 lines; the validation owner moved from
234 to 232 lines and the dedicated OperationalReadinessCapabilityContext is 13
lines.

Next candidate:
Re-rank the remaining Schema capability/model-limit responsibility clusters.

Blocked:
No.
