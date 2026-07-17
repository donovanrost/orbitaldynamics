# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema validation-assessment JSON property-dispatch extraction.

Status:
Published as `4e361602`.

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
`OrbitalDynamics.Schema` now routes both validation-assessment contracts
through one guarded facade clause. The new
`ValidationAssessmentPropertyDispatch` owns contract-kind dispatch, validation
capability lookups, focused field selection, and dependency wiring while
preserving the facade's private schema callbacks and default property fallback.
`schema.ex` drops from 9,760 to 9,745 lines.

Verification gaps:
- `mix compile --warnings-as-errors`
- validation-policy, JSON export, schema export, and export-task files:
  23 tests passed
- full schema export regeneration: no checked-in diff
- checked-in schema aggregate digest unchanged:
  `95051be82cec8a75634e4e8712dadd102888f59998d2c26ebe7c36065d824d3b`
- scoped `mix format --check-formatted`
- `git diff --check` and new-file diff hygiene
- dispatcher compile-connected graph: no dependency edge
- dispatcher caller: `OrbitalDynamics.Schema` at runtime only
- bounded read-only review: clean, no findings

Last completed slice:
Schema validation-assessment property dispatch published as `4e361602`: two
contracts now route through one cohesive internal dispatcher, 23 focused/export
tests passed, full regeneration was byte-identical, and bounded review found no
blocker.

Next candidate:
Audit adjacent schema-validation report/batch property dispatch as the next
cohesive validation contract family.

Blocked:
No.
