# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema validation-report JSON property-dispatch extraction.

Status:
Published as `6e25b831`.

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
`OrbitalDynamics.Schema` now routes both schema-validation contracts through
one guarded facade clause. The new `SchemaValidationPropertyDispatch` owns
report/batch kind resolution, the shared contract callback, focused field
selection, nested schema dependency wiring, and default fallback. `schema.ex`
drops from 9,745 to 9,725 lines.

Verification gaps:
- `mix compile --warnings-as-errors`
- validation-scoring, JSON export, schema export, and export-task files:
  28 tests passed
- full schema export regeneration: no checked-in diff
- checked-in schema aggregate digest unchanged:
  `95051be82cec8a75634e4e8712dadd102888f59998d2c26ebe7c36065d824d3b`
- scoped `mix format --check-formatted`
- `git diff --check` and new-file diff hygiene
- dispatcher compile-connected graph: no dependency edge
- dispatcher caller: `OrbitalDynamics.Schema` at runtime only
- bounded read-only review: clean, no findings

Last completed slice:
Schema validation-report property dispatch published as `6e25b831`: report and
batch contracts now route through one cohesive internal dispatcher, 28
focused/export tests passed, full regeneration was byte-identical, and bounded
review found no blocker.

Next candidate:
Audit adjacent campaign-request/study-manifest lint property dispatch as the
next cohesive export family; leave the single migration clause in the facade
unless a broader lifecycle boundary emerges.

Blocked:
No.
