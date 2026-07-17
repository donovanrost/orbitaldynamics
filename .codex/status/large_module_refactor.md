# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema priority-field evidence contract extraction.

Status:
Ready for implementation.

Selected slice:
Extract guarded priority-field evidence count validation into
`Schema.PriorityFieldEvidenceContracts.validate/3`. Point the contact-allocation
and operator-review callback captures at the new owner and remove both private
facade clauses.

Why this slice:
The two self-contained clauses validate only priority-field evidence maps and
serve two independent consumers. They depend solely on `error/2`, so a dedicated
internal contract module gives the responsibility a stable owner without
pulling facade state or changing callback shapes.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact validation issue ordering,
paths and messages, cadence-import behavior, JSON Schema bytes, and aggregate
schema export bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/priority_field_evidence_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused cadence-import, readiness, and review-import handoff contract tests
- JSON Schema contract/export tests and full checked-in schema regeneration
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The new owner contains the exact map-guarded and fallback clauses, both callback
captures point to it, the facade clauses are gone, map iteration and error
ordering remain exact, validation and schema exports remain byte-for-byte
stable, focused tests pass, and bounded review finds no blocker.

Verification gaps:
- Implementation and verification pending.

Tests run:
- Selection only; implementation verification pending.

Behavior/schema changes:
None.

Last completed slice:
Schema deferred-priority callback ownership cleanup published as `b12eb661`:
both callback bags now point directly to the contention owner, the pure facade
delegate was removed, 182 schema/export tests passed, full export bytes stayed
exact, and bounded review was clean.

Next candidate:
After this boundary, audit the remaining priority-override count helper and the
single CandidateDiff source-window-lineage pipeline before selecting another
owner family.

Blocked:
No.
