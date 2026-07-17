# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema link-capacity handoff callback ownership cleanup.

Status:
Selected; implementation pending.

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

Verification gaps:
- Implementation and verification pending.

Tests run:
- Pending.

Behavior/schema changes:
None intended.

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
