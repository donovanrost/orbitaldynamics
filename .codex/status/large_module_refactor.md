# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema model-capability JSON property-dispatch extraction.

Status:
Published.

Selected slice:
Extract property dispatch for environment-model, environment-provider, and
subsystem-model capabilities from `OrbitalDynamics.Schema` into one internal
model-capability dispatcher.

Why this slice:
The three adjacent clauses share `CapabilityJsonSchema`, identical dependency
shape, and focused capability contract coverage. Optimizer, Monte Carlo,
migration, and capability runtime behavior remain out of scope.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact JSON Schema maps and
validators for the three capability contracts, bundle ordering, and checked-in
schema bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- new model-capability property-dispatch module
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused optimizer/capability and registry-capability tests
- JSON schema export tests
- schema export task tests
- full checked-in export regeneration and aggregate digest comparison
- compile, format, xref, diff hygiene, and bounded review

Definition of done:
The three facade clauses become one guarded delegate to the internal
dispatcher; runtime schemas, validators, bundle ordering, and checked-in
exports remain exact; focused and export tests pass; and bounded review finds
no blocker.

Outcome:
The three facade clauses are now one guarded delegate to
`OrbitalDynamics.Schema.ModelCapabilityPropertyDispatch`. The internal
dispatcher preserves contract-to-kind routing, exact schema contracts, stable
identity and validation-level dependencies, focused-field selection, and the
common-property fallback. The facade is 9,694 lines; the new dispatcher is 34
lines. Implementation published as `84444b3a`.

Verification gaps:
- `mix compile --warnings-as-errors` passed.
- 29 focused capability, registry, JSON export, schema export, and export-task
  tests passed.
- Full checked-in export regeneration remained byte-identical at aggregate
  digest `95051be82cec8a75634e4e8712dadd102888f59998d2c26ebe7c36065d824d3b`.
- Scoped format, diff hygiene, and xref checks passed; xref reports only the
  expected runtime caller from `OrbitalDynamics.Schema`.
- Bounded read-only review found no blocker or follow-up finding.
- None for this slice.

Last completed slice:
Schema model-capability property dispatch published as `84444b3a`: the three
environment/provider/subsystem capability contracts now route through one
cohesive internal dispatcher, 29 focused/export tests passed, full regeneration
was byte-identical, and bounded review found no blocker.

Next candidate:
Extract the four adjacent provider-counteroffer report, review, import-readiness,
and plan-impact property clauses into one internal provider-counteroffer
dispatcher. Preserve each focused predicate and dependency context, lazy
StationCalendar capability lookups, common fallback, and exact exports. Leave
the surrounding maneuver-recommendation and candidate-rejection clauses in the
facade.

Blocked:
No.
