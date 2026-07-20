# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema readiness model-limit routing cleanup.

Status:
Selected; implementation not started.

Selected boundary:
Route operational-readiness and quality-gate JSON Schema property dispatch
directly to `OrbitalDynamics.Schema.OperationalReadinessValidation` model-limit
APIs and remove ten facade pass-through helpers.
Preserve all `OrbitalDynamics.Schema` public facades, JSON Schema output, and
validation behavior.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,558 lines.
- Ten readiness/quality-gate model-limit helpers are pure one-hop delegates to
  the existing validation owner.
- The selected code has one responsibility: supply readiness report, summary,
  execution-boundary, quality-gate report, and specialized quality-gate
  model-limit lists to JSON Schema property dispatch and validation.
- Property-dispatch composition, other
  artifact-family validation, JSON Schema generation, and all public routing
  remain outside the boundary.
- Exact model-limit values and ordering, callback wiring, validation results,
  generated JSON Schema, and checked-in exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema source-evidence validation/status routing cleanup, selected in
`bbb7ebe4` and implemented in `8a124313`.
`schema.ex` moved from 6,580 to 6,558 lines by consolidating status enums and
validation routing in SourceEvidenceValidation.

Next candidate:
After this slice, re-rank the remaining schema responsibility clusters while
preserving dependency-injecting adapters.

Blocked:
No.
