# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-allocation expiration-summary callback ownership cleanup.

Status:
Completed and published.

Selected slice:
Point the cadence-import manifest and operator-review package expiration-summary
captures directly at
`Schema.ContactAllocationHandoffContracts.validate_expiration_summary/3`, then
remove the pure `Schema` facade delegate.

Why this slice:
Both callback consumers already share the same owner API and the facade helper
only forwards its three arguments unchanged. This is a single-owner,
two-capture boundary independent of contact-allocation evidence injection.

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
Both selected captures point directly to the contact-allocation owner, the pure
facade delegate is gone, validation ordering remains exact, validation and
schema exports remain byte-for-byte stable, focused tests pass, and bounded
review finds no blocker.

Verification gaps:
- None for this slice.

Tests run:
- `mix compile --warnings-as-errors`
- 109 focused cadence-import, operator-review, and contact-allocation tests
- 182 complete schema-contract and schema-export tests
- full checked-in schema export regeneration; no schema diff
- aggregate schema bundle digest unchanged:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`
- `mix format --check-formatted`
- `git diff --check`
- compile-connected xref check for `schema.ex`
- bounded read-only review: clean, no findings

Outcome:
Both expiration-summary captures now point directly to
`ContactAllocationHandoffContracts`. The pure facade delegate is gone and
`schema.ex` decreased from 8,225 to 8,217 lines.

Behavior/schema changes:
None.

Last completed slice:
Schema contact-allocation expiration-summary callback ownership cleanup
published as `7ceb704f`: both captures now point directly to the owner, the pure
facade delegate was removed, 182 schema/export tests passed, full export bytes
stayed exact, and bounded review was clean.

Next candidate:
Point the single operator-review package quality-gate summary capture directly
at `QualityGateHandoffContracts.validate_summary/3` and remove the pure facade
delegate.

Blocked:
No.
