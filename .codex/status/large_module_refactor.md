# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-contention handoff callback ownership cleanup.

Status:
Completed and published.

Selected slice:
Point the contact-contention general and cadence-source-review handoff callback
captures directly at the existing
`Schema.ContactContentionHandoffContracts` owner. Remove the general delegate
and both clauses of the cadence delegate.

Why this slice:
The general delegate is a pure pass-through. The cadence facade wrapper has a
specialized clause plus permissive fallback, and the existing owner exposes the
same specialized and fallback clauses. Three general capture sites and one
cadence-specific site can therefore point directly to the owner without moving
contact-contention validation logic or issue ordering.

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
`ContactContentionHandoffContracts` validator, the general delegate and both
cadence clauses are gone,
validation and schema exports remain byte-for-byte stable, focused tests pass,
and bounded review finds no blocker.

Outcome:
All contact-contention callback lists now capture the existing
`ContactContentionHandoffContracts` validators directly. The general delegate
and specialized/fallback cadence clauses were removed, reducing `schema.ex`
from 8,942 to 8,919 lines without changing callback keys, validation order,
fallback behavior, results, or checked-in schema bytes.

Verification gaps:
- None for this slice.

Tests run:
- `mix compile --warnings-as-errors`
- 45 focused contact-contention-referencing schema contract tests
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
