# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema quality-gate summary callback ownership cleanup.

Status:
Ready for implementation.

Selected slice:
Point the operator-review package quality-gate summary capture directly at
`Schema.QualityGateHandoffContracts.validate_summary/3`, then remove the pure
`Schema` facade delegate.

Why this slice:
The single callback already matches the owner’s public three-argument API and
the facade helper only forwards its arguments unchanged. Keeping this isolated
preserves a minimal owner-bounded review surface.

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
The selected capture points directly to the quality-gate owner, the pure facade
delegate is gone, validation ordering remains exact, validation and schema
exports remain byte-for-byte stable, focused tests pass, and bounded review
finds no blocker.

Verification gaps:
- Implementation and verification pending.

Tests run:
- Selection only; implementation verification pending.

Behavior/schema changes:
None.

Last completed slice:
Schema contact-allocation expiration-summary callback ownership cleanup
published as `7ceb704f`: both captures now point directly to the owner, the pure
facade delegate was removed, 182 schema/export tests passed, full export bytes
stayed exact, and bounded review was clean.

Next candidate:
After this boundary, remap the remaining local callback captures by owner and
separate pure delegates from callbacks that still carry facade-owned state.

Blocked:
No.
