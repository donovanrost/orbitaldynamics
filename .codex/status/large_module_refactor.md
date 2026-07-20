# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema resource-projection metadata direct routing.

Status:
Completed and pushed.

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
Removed the one-hop resource-projection report models and model-limits
wrappers and routed both property-dispatch captures directly to
ResourceValidation.
`schema.ex` moved from 6,151 to 6,145 lines.

Verification:
- Strict focused resource/filter/export baseline before routing: 22 passed.
- The same strict focused suite after routing: 22 passed.
- Strict full schema-export task plus adjacent candidate-refresh provenance,
  fixture-visibility, and validation coverage: 5 passed.
- `mix xref callers OrbitalDynamics.Schema.ResourceValidation` reports the
  expected `schema.ex (runtime)` caller alongside
  `contact_report_validation.ex (runtime)`.
- Static search confirms both wrapper definitions and indirect captures are
  gone from `schema.ex`.
- `git diff --check` passed; no checked-in schema export changed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `e188b381` pushed to `main`.

Behavior/schema changes:
None. Public facades, callback timing, report model/model-limit values and
ordering, generated JSON Schema, validation behavior, and checked-in exports
remain unchanged.

Last completed slice:
Schema resource-projection metadata direct routing, selected in `95a1349a`
and implemented in `e188b381`.
`schema.ex` moved from 6,151 to 6,145 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
