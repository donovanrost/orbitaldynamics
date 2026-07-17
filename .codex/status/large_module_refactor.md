# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema optimizer-report JSON property-dispatch extraction.

Status:
Selected.

Selected slice:
Extract property dispatch for ranking-comparison and Pareto-frontier reports
from `OrbitalDynamics.Schema` into one internal optimizer-report dispatcher.

Why this slice:
The two adjacent clauses duplicate the same contract-sensitive
`OptimizerReportJsonSchema` predicate and complete lazy context, and have
focused optimizer-objective coverage. Score-term and optimizer runtime behavior
remain out of scope.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact JSON Schema maps and
validators for the two optimizer-report contracts, bundle ordering,
and checked-in schema bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- new optimizer-report property-dispatch module
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused optimizer-objective contract tests
- JSON schema export tests
- schema export task tests
- full checked-in export regeneration and aggregate digest comparison
- compile, format, xref, diff hygiene, and bounded review

Definition of done:
The two facade clauses become one guarded delegate to the internal
dispatcher; runtime schemas, validators, bundle ordering, and checked-in
exports remain exact; focused and export tests pass; and bounded review finds
no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
Schema objective-report property dispatch published as `d6ae77c8`:
satisfaction and tradeoff reports now route through one cohesive internal
dispatcher, 24 focused/export tests passed, full regeneration was
byte-identical, and bounded review found no blocker.

Next candidate:
Audit one adjacent multi-contract report/property family after this slice is
published. Leave single-contract neighbors in the facade unless a broader
cohesive boundary emerges.

Blocked:
No.
