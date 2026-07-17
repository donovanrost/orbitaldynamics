# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema link-capacity handoff callback ownership cleanup.

Status:
Completed and verified; publishing.

Selected slice:
Point the link-capacity count-list, general source-match, and
cadence-source-review callback captures directly at the existing
`Schema.LinkCapacityHandoffContracts` owner. Remove the count-list delegate and
both clauses of each source-match delegate.

Why this slice:
The count-list delegate is a pure pass-through. Both source-match facade
wrappers duplicate specialized and permissive fallback clauses already exposed
by the owner. Three count-list, three general source-match, and one cadence
capture form one seven-position ownership boundary without moving validation
logic or changing issue order.

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
`LinkCapacityHandoffContracts` validator, the count-list delegate and both
source-match wrapper pairs are gone,
validation and schema exports remain byte-for-byte stable, focused tests pass,
and bounded review finds no blocker.

Outcome:
All link-capacity count-list and source-match callback lists now capture the
existing `LinkCapacityHandoffContracts` validators directly. The count-list
delegate and both specialized/fallback source-match wrapper pairs were removed,
reducing `schema.ex` from 8,919 to 8,885 lines without changing callback keys,
iteration or issue order, fallback behavior, results, or checked-in schema
bytes.

Verification gaps:
- None for this slice.

Tests run:
- `mix compile --warnings-as-errors`
- 47 focused link-capacity-referencing schema contract tests
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
Schema contact-contention handoff callback ownership cleanup published as
`cecaa971`: all general/cadence captures now point directly to their existing
contract owner, including equivalent cadence fallback behavior; 182
schema/export tests passed, full export bytes stayed exact, and bounded review
was clean.

Next candidate:
Audit the link-capacity callback family. Count-list, source-match, and
cadence-source-review callbacks target the existing
`LinkCapacityHandoffContracts` owner; select only after confirming all seven
capture positions and exact specialized/fallback behavior.

Blocked:
No.
