# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema filter-report JSON property-dispatch extraction.

Status:
Selected.

Selected slice:
Extract property dispatch for contact-filter and resource-filter reports from
`OrbitalDynamics.Schema` into one internal filter-report dispatcher.

Why this slice:
The two adjacent report clauses share stable identity and suppressed-candidate
schema dependencies, retain explicit family-specific assumptions/model limits,
and have focused filter-report coverage. Allocation summaries, resource
projection, and filter runtime behavior remain out of scope.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact JSON Schema maps and
validators for the two filter-report contracts, bundle ordering,
and checked-in schema bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- new filter-report property-dispatch module
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused filter-report contract tests
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
Schema contact-allocation-summary property dispatch published as `9f68e87c`:
the five summary contracts now route through one cohesive internal dispatcher,
31 focused/export tests passed, full regeneration was byte-identical, and
bounded review found no blocker.

Next candidate:
Audit one adjacent multi-contract report/property family after this slice is
published. Leave single-contract neighbors in the facade unless a broader
cohesive boundary emerges.

Blocked:
No.
