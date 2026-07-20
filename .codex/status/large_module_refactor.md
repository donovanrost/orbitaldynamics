# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema resource-projection metadata direct routing.

Status:
Selected; implementation not started.

Selected boundary:
Remove the Schema facade's one-hop resource-projection report models and model
limits wrappers.
Route the property-dispatch callback captures directly to
`ResourceValidation.resource_projection_report_models/0` and
`resource_projection_report_model_limits/0`.
Keep property-dispatch composition, resource schema construction, validators
that add facade-owned callbacks, and all public facades in
`OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,151 lines.
- Both wrappers only call the same-arity ResourceValidation owner APIs and add
  no guards, defaults, transformation, caching, or ordering.
- Each wrapper has exactly one callback-capture consumer in resource-projection
  property dispatch.
- Exact callback timing, report model/model-limit values and ordering,
  generated JSON Schema, validation results, and checked-in exports must remain
  unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema candidate-rejection source-row validation direct routing, selected in
`07f4e3d0` and implemented in `ec799ada`.
`schema.ex` moved from 6,154 to 6,151 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
