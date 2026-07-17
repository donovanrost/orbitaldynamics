# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-contention handoff callback ownership cleanup.

Status:
Selected; implementation pending.

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

Verification gaps:
- Implementation and verification pending.

Tests run:
- Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema command-window/maneuver handoff callback ownership cleanup published as
`2c91d4e8`: both general/cadence callback pairs now point directly to their
existing contract owner; 182 schema/export tests passed, full export bytes
stayed exact, and bounded review was clean.

Next candidate:
Audit the contact-contention handoff callback family. Its general/cadence
callbacks target the existing `ContactContentionHandoffContracts` owner, but
the facade also has a cadence fallback clause; select only after proving that
the owner retains the same fallback and all four general/one cadence capture
positions can move without changing issue order.

Blocked:
No.
