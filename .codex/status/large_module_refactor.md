# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema station-calendar handoff callback ownership cleanup.

Status:
Selected; implementation pending.

Selected slice:
Point the station-calendar count-list, general source-match, and
cadence-source-review callback captures directly at the existing
`Schema.StationCalendarHandoffContracts` owner. Remove the general and
count-list delegates plus both clauses of the cadence wrapper.

Why this slice:
The general and count-list delegates are pure pass-throughs to total owner
functions. The cadence wrapper duplicates the owner's specialized and
permissive fallback clauses. Three count-list, three general source-match, and
one cadence capture form one seven-position ownership boundary without moving
station-calendar validation or changing ordered count checks.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact validation issue ordering,
paths and messages, cadence-import behavior, JSON Schema bytes, and aggregate
schema export bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused cadence-import, readiness, and review-import handoff contract tests
- JSON Schema contract/export tests and full checked-in schema regeneration
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
Every callback list directly captures the corresponding public
`StationCalendarHandoffContracts` validator, the general/count-list delegates
and both cadence clauses are gone,
validation and schema exports remain byte-for-byte stable, focused tests pass,
and bounded review finds no blocker.

Verification gaps:
- Implementation and verification pending.

Tests run:
- Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema link-capacity handoff callback ownership cleanup published as
`49d41864`: all count-list and general/cadence source-match captures now point
directly to their existing contract owner; 182 schema/export tests passed,
full export bytes stayed exact, and bounded review was clean.

Next candidate:
Audit the station-calendar callback family. Count-list, source-match, and
cadence-source-review callbacks target the existing
`StationCalendarHandoffContracts` owner across seven capture positions; select
only after confirming exact total/specialized/fallback behavior and count-list
iteration order.

Blocked:
No.
