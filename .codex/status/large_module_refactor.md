# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema station-reservation-summary JSON property-dispatch extraction.

Status:
Review complete; ready to publish.

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
The three facade clauses are now one guarded delegate to
`OrbitalDynamics.Schema.StationReservationSummaryPropertyDispatch`. The
internal dispatcher preserves contract-to-module routing, focused-field
selection, the shared review/hold row callback, the distinct import-readiness
row callback, shared model-limit/stable-identity dependencies, and the common
fallback. The facade is 9,592 lines; the new dispatcher is 56 lines.

Verification gaps:
- `mix compile --warnings-as-errors` passed.
- 28 focused station-provider, JSON export, schema export, and export-task tests
  passed.
- Full checked-in export regeneration remained byte-identical at aggregate
  digest `95051be82cec8a75634e4e8712dadd102888f59998d2c26ebe7c36065d824d3b`.
- Scoped format, diff hygiene, and xref checks passed; xref reports only the
  expected runtime caller from `OrbitalDynamics.Schema`.
- Bounded read-only review found no blocker or follow-up finding.

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
