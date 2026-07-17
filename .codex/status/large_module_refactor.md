# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema validation-assessment JSON property-dispatch extraction.

Status:
Selected.

Selected slice:
Extract property dispatch for model-acceptance reports and validation
safety-case summaries from `OrbitalDynamics.Schema` into one internal
validation-assessment dispatcher.

Why this slice:
The two adjacent clauses form one assessment family, share stable identity,
model-limit, validation capability, and evidence dependencies, and are jointly
covered by focused validation-policy tests. Schema reports, migration, and
executable validators remain out of scope.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact JSON Schema maps for the
two assessment contracts, executable validation behavior, bundle
ordering, and checked-in schema bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- new validation-assessment property-dispatch module
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused validation-policy and JSON export tests
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
Schema validation-evidence property dispatch published as `c1498887`: four
contracts now route through one cohesive internal dispatcher, 25 focused/export
tests passed, full regeneration was byte-identical, and bounded review found no
blocker.

Next candidate:
Audit adjacent schema-validation report/batch property dispatch after this
slice is published.

Blocked:
No.
