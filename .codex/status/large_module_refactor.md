# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema model-capability JSON property-dispatch extraction.

Status:
Selected.

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
Pending.

Verification gaps:
- Pending.

Last completed slice:
Schema lint-report property dispatch published as `a64b4fde`: campaign-request
and study-manifest lint contracts now route through one cohesive internal
dispatcher, 23 focused/export tests passed, full regeneration was
byte-identical, and bounded review found no blocker.

Next candidate:
Audit one adjacent multi-contract report/property family after this slice is
published. Leave the single optimizer, migration, and Monte Carlo clauses in
the facade unless a broader cohesive boundary emerges.

Blocked:
No.
