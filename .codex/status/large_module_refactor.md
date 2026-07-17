# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema validation-report JSON property-dispatch extraction.

Status:
Selected.

Selected slice:
Extract property dispatch for schema-validation reports and batch reports from
`OrbitalDynamics.Schema` into one internal validation-report dispatcher.

Why this slice:
The two adjacent clauses already share one JSON-schema helper, identical
dependency wiring, and only differ by `:report` versus `:batch` routing. They
are jointly covered by focused validation-scoring and export tests; migration
and executable validators remain out of scope.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact JSON Schema maps for the
two schema-validation contracts, executable validation behavior, bundle
ordering, and checked-in schema bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- new validation-report property-dispatch module
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused validation-scoring and JSON export tests
- schema export task tests
- full checked-in export regeneration and aggregate digest comparison
- compile, format, xref, diff hygiene, and bounded review

Definition of done:
The two facade clauses become one guarded delegate to the internal dispatcher;
runtime schemas,
validators, bundle ordering, and checked-in exports remain exact; focused and
export tests pass; and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
Schema validation-assessment property dispatch published as `4e361602`: two
contracts now route through one cohesive internal dispatcher, 23 focused/export
tests passed, full regeneration was byte-identical, and bounded review found no
blocker.

Next candidate:
Audit adjacent schema-migration property dispatch after this slice is
published.

Blocked:
No.
