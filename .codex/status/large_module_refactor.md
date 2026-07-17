# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema deferred-priority callback ownership cleanup.

Status:
Completed and published.

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
- None for this slice.

Tests run:
- `mix compile --warnings-as-errors`
- 10 focused contact-allocation and operator-review tests
- 182 complete schema-contract and schema-export tests
- full checked-in schema export regeneration; no schema diff
- aggregate schema bundle digest unchanged:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`
- `mix format --check-formatted`
- `git diff --check`
- compile-connected xref check for `schema.ex`
- bounded read-only review: clean, no findings

Outcome:
Both deferred-priority callback bags now point directly to
`ContactContentionReportContracts`. The pure facade delegate is gone, both bag
orders remain exact, and `schema.ex` decreased from 8,051 to 8,043 lines.

Behavior/schema changes:
None.

Last completed slice:
Schema deferred-priority callback ownership cleanup published as `b12eb661`:
both callback bags now point directly to the contention owner, the pure facade
delegate was removed, 182 schema/export tests passed, full export bytes stayed
exact, and bounded review was clean.

Next candidate:
Extract priority-field evidence count validation from `Schema` into a dedicated
internal contract module, point its two callback captures at the new owner, and
preserve the exact guarded/fallback clauses and error ordering.

Blocked:
No.
