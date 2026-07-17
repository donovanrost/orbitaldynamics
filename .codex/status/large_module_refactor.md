# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema lint-report JSON property-dispatch extraction.

Status:
Review complete; ready to publish.

Selected slice:
Extract property dispatch for campaign-request and study-manifest lint reports
from `OrbitalDynamics.Schema` into one internal lint-report dispatcher.

Why this slice:
The two adjacent clauses share `LintReportJsonSchema`, stable identity
dependencies, and one focused lint contract test file. Strategy-branch,
migration, and executable lint behavior remain out of scope.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact JSON Schema maps for the
two lint-report contracts, executable lint/validation behavior, bundle
ordering, and checked-in schema bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- new lint-report property-dispatch module
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused lint/strategy-branch and JSON export tests
- schema export task tests
- full checked-in export regeneration and aggregate digest comparison
- compile, format, xref, diff hygiene, and bounded review

Definition of done:
The two facade clauses become one guarded delegate to the internal dispatcher;
runtime schemas,
validators, bundle ordering, and checked-in exports remain exact; focused and
export tests pass; and bounded review finds no blocker.

Outcome:
The two facade clauses are now one guarded delegate to
`OrbitalDynamics.Schema.LintReportPropertyDispatch`. The internal dispatcher
preserves each contract's original field predicate, builder context, dependency
schemas, study-manifest schema version, and common-property fallback. The
facade is 9,718 lines; the new dispatcher is 53 lines.

Verification gaps:
- `mix compile --warnings-as-errors` passed.
- 23 focused lint, JSON export, schema export, and export-task tests passed.
- Full checked-in export regeneration remained byte-identical at aggregate
  digest `95051be82cec8a75634e4e8712dadd102888f59998d2c26ebe7c36065d824d3b`.
- Scoped format, diff hygiene, and xref checks passed; xref reports only the
  expected runtime caller from `OrbitalDynamics.Schema`.
- Bounded read-only review found no blocker or follow-up finding.

Last completed slice:
Schema validation-report property dispatch published as `6e25b831`: report and
batch contracts now route through one cohesive internal dispatcher, 28
focused/export tests passed, full regeneration was byte-identical, and bounded
review found no blocker.

Next candidate:
Audit one adjacent capability/property family after this slice is published;
leave the single migration clause in the facade unless a broader lifecycle
boundary emerges.

Blocked:
No.
