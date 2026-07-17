# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema station-calendar handoff callback ownership cleanup.

Status:
Completed and published.

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

Outcome:
All station-calendar count-list and source-match callback lists now capture the
existing `StationCalendarHandoffContracts` validators directly. The general and
count-list delegates plus specialized/fallback cadence wrapper were removed,
reducing `schema.ex` from 8,885 to 8,854 lines without changing source
precedence, count-check or issue order, fallback behavior, results, or
checked-in schema bytes.

Verification gaps:
- None for this slice.

Tests run:
- `mix compile --warnings-as-errors`
- 81 focused station-calendar-referencing schema contract tests
- 182 complete schema-contract and schema-export tests
- full checked-in schema export regeneration; no schema diff
- aggregate schema bundle digest unchanged:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`
- `mix format --check-formatted`
- `git diff --check`
- compile-connected xref check for `schema.ex`
- bounded read-only review: clean, no findings

Behavior/schema changes:
None.

Last completed slice:
Schema station-calendar handoff callback ownership cleanup published as
`a7b5f246`: all count-list and general/cadence source-match captures now point
directly to their existing contract owner; 182 schema/export tests passed,
full export bytes stayed exact, and bounded review was clean.

Next candidate:
Audit the resource-projection handoff callback family. Several delegates target
`ResourceProjectionHandoffContracts`, but count and battery paths also carry
predicate/row-selection dependencies. Select only a cohesive subset whose
callbacks and fallback clauses can be moved without creating a broad callback
bag or crossing the separate own-flow validator path.

Blocked:
No.
