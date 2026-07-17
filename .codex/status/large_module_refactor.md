# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema station-reservation-summary JSON property-dispatch extraction.

Status:
Selected.

Selected slice:
Extract property dispatch for station-reservation review summary, hold summary,
and hold import-readiness summary from `OrbitalDynamics.Schema` into one
internal reservation-summary dispatcher.

Why this slice:
The three adjacent clauses share station-calendar model limits, stable identity,
summary row semantics, and focused station-provider contract coverage. Station
reservation/calendar reports, provider schemas, and runtime behavior remain
out of scope.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact JSON Schema maps and
validators for the three reservation-summary contracts, bundle ordering, and
checked-in schema bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- new station-reservation-summary property-dispatch module
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused station-provider contract tests
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
Schema timeline-report property dispatch published as `39a16f36`: operational
timeline report, timeline-diff report, and timeline-diff summary now route
through one cohesive internal dispatcher, 49 focused/export tests passed, full
regeneration was byte-identical, and bounded review found no blocker.

Next candidate:
Audit one adjacent multi-contract station property family after this slice is
published. Leave station reports/provider clauses in the facade unless a
broader cohesive boundary emerges.

Blocked:
No.
