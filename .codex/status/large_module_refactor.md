# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline publication-summary callback ownership cleanup.

Status:
Ready for implementation.

Selected slice:
Give `Schema.TimelineHandoffContracts` an owner-owned three-argument publication
matching entry point that uses its existing summary validator. Point the three
optional-summary and three publication-matching callback captures directly at
the owner, then remove the two pure `Schema` facade wrappers.

Why this slice:
The owner already implements the complete optional-summary validator and
publication matching pipeline. Its four-argument entry point only receives that
same owner validator back from `Schema`, so an owner-owned default removes the
callback inversion while preserving the existing implementation, fallback
clauses, field traversal, and issue order.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact validation issue ordering,
paths and messages, cadence-import behavior, JSON Schema bytes, and aggregate
schema export bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/timeline_handoff_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused cadence-import, readiness, and review-import handoff contract tests
- JSON Schema contract/export tests and full checked-in schema regeneration
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
All six selected captures point directly to `TimelineHandoffContracts`, its
three-argument matching entry point owns the existing validator dependency, the
two facade wrappers are gone, issue ordering remains exact, validation and
schema exports remain byte-for-byte stable, focused tests pass, and bounded
review finds no blocker.

Verification gaps:
- Implementation and verification pending.

Tests run:
- Selection only; implementation verification pending.

Behavior/schema changes:
None.

Last completed slice:
Schema timeline callback ownership cleanup published as `f2520e49`: seventeen
captures now point directly to `TimelineHandoffContracts`, eleven pure facade
delegates were removed, 182 schema/export tests passed, full export bytes stayed
exact, and bounded review was clean.

Next candidate:
After this boundary, audit the remaining `Schema` callback captures by owner and
capture count before selecting another bounded family.

Blocked:
No.
