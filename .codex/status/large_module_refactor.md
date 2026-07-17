# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema lint-report JSON property-dispatch extraction.

Status:
Selected.

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
Pending.

Verification gaps:
- Pending.

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
