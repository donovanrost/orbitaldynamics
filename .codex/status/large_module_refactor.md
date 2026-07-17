# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema resource-projection JSON property-dispatch extraction.

Status:
Selected.

Selected slice:
Extract property dispatch for resource-projection report and
resource-projection flow summary from `OrbitalDynamics.Schema` into one
internal resource-projection dispatcher.

Why this slice:
The two adjacent clauses share stable identity, model-limit, and assumptions
dependencies while retaining explicit report/summary row paths and focused
resource contract coverage. Filter reports, contention, and projection runtime
behavior remain out of scope.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact JSON Schema maps and
validators for the two resource-projection contracts, bundle ordering,
and checked-in schema bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- new resource-projection property-dispatch module
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused resource contract tests
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
Schema filter-report property dispatch published as `6646d27e`: contact and
resource filter reports now route through one cohesive internal dispatcher, 23
focused/export tests passed, full regeneration was byte-identical, and bounded
review found no blocker.

Next candidate:
Audit one adjacent multi-contract report/property family after this slice is
published. Leave single-contract neighbors in the facade unless a broader
cohesive boundary emerges.

Blocked:
No.
