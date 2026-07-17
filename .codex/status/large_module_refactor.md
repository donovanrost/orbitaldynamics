# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema deferred-priority callback ownership cleanup.

Status:
Ready for implementation.

Selected slice:
Point the contact-allocation domain callback and operator-review row callback
for deferred contention priority directly at
`Schema.ContactContentionReportContracts.validate_deferred_priority/3`. Remove
the pure facade delegate across two positions.

Why this slice:
The contention owner already exposes the exact `/3` validator and the facade
helper only forwards arguments. Both callback keys and their surrounding bag
order can remain unchanged without touching contact-allocation domain behavior
or operator-review dispatch.

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
Both callback positions call the contention owner directly, the pure facade
delegate is gone, callback-key ordering and issue behavior remain exact,
validation and schema exports remain byte-for-byte stable, focused tests pass,
and bounded review finds no blocker.

Verification gaps:
- Implementation and verification pending.

Tests run:
- Selection only; implementation verification pending.

Behavior/schema changes:
None.

Last completed slice:
Schema communications-report validation ownership cleanup published as
`357bc8f0`: six positions now call their report owners directly, four pure
facade delegates were removed, 182 schema/export tests passed, full export
bytes stayed exact, and bounded review was clean.

Next candidate:
After this boundary, audit the single CandidateDiff source-window-lineage
pipeline and the remaining priority evidence helpers before selecting another
owner family.

Blocked:
No.
