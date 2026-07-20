# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema operational-readiness artifact owner routing.

Status:
Selected; implementation pending.

Selected boundary:
Add an owner-default artifact dispatcher to OperationalReadinessValidation for
four readiness artifacts, five operational quality-gate summaries, and the
quality-gate report. Derive requirements from the readiness, operational
quality-gate, and quality-gate registries, then route all ten direct Schema
clauses. Keep every specialized owner API unchanged.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,889 lines; the other
  targeted public facades are now 164 to 524 lines.
- Ten direct clauses repeat required-field setup before calling APIs already
  owned by OperationalReadinessValidation.
- Three registry modules collectively own every required-field definition.
- The owner already holds all model limits, nested callbacks, report/summary
  validators, and quality-gate row validation.
- No route needs recursive Schema lookup or facade-local callbacks.
- Existing specialized owner APIs remain the customization boundary.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Required fields, model limits, callbacks, validation ordering
and paths, public Schema APIs, validation results, and checked-in exports must
remain unchanged.

Last completed slice:
Schema accepted-state/candidate-refresh validation context extraction, selected
in `139671e3` and implemented in `3411b55c`.
`schema.ex` moved from 4,939 to 4,889 lines.

Next candidate:
Implement and verify the selected operational-readiness owner routing, then
re-rank the remaining Schema responsibility clusters.

Blocked:
No.
