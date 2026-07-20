# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema optional-readiness validation routing cleanup.

Status:
Selected; implementation not started.

Selected boundary:
Complete direct routing to
`OrbitalDynamics.Schema.OperationalReadinessValidation` by replacing the two
remaining optional report callback wrappers.
Preserve all `OrbitalDynamics.Schema` public facades and validation behavior.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,535 lines.
- All readiness validation/model-limit routing now points directly to the
  focused owner except optional readiness-report and quality-gate-report
  callbacks in the campaign-plan table.
- The selected code has one responsibility: validate optional embedded
  readiness and quality-gate reports.
- Callback-table composition, other
  artifact-family validation, JSON Schema generation, and all public routing
  remain outside the boundary.
- Exact issue ordering, paths, messages, malformed-input behavior, callback
  wiring, and public validation results must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema readiness model-limit routing cleanup, selected in `2dac5322` and
implemented in `df639635`.
`schema.ex` moved from 6,558 to 6,535 lines by routing directly to the existing
OperationalReadinessValidation model-limit APIs.

Next candidate:
After this slice, re-rank the larger timeline capability/context boundary for
a dedicated extraction.

Blocked:
No.
