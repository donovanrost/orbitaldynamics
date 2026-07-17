# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-allocation expiration-summary callback ownership cleanup.

Status:
Ready for implementation.

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
- Implementation and verification pending.

Tests run:
- Selection only; implementation verification pending.

Behavior/schema changes:
None.

Last completed slice:
Schema suppression duplicate-evidence callback ownership cleanup published as
`9d901f0d`: three captures now use the owner’s default evidence pipeline, two
pure facade helpers were removed, 182 schema/export tests passed, full export
bytes stayed exact, and bounded review was clean.

Next candidate:
After this boundary, retarget the single quality-gate handoff summary capture if
its owner API and callback position remain exact.

Blocked:
No.
