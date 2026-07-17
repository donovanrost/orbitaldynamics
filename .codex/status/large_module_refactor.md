# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema scoped-downlink callback ownership cleanup.

Status:
Ready for implementation.

Selected slice:
Point the positional strategy-recommendation callback plus the cadence-import
and operator-review keyword captures directly at
`Schema.ScopedDownlinkContextContracts.validate/3`. Remove the pure facade
delegate across three positions.

Why this slice:
The owner already exposes the exact `/3` context validator and the facade only
forwards its arguments. The positional strategy callback and both keyword-bag
entries can retain their current slots and keys without owner or consumer
changes.

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
All three positions point directly to `ScopedDownlinkContextContracts`, the pure
facade delegate is gone, callback slots and list positions remain exact,
validation and schema exports remain byte-for-byte stable, focused tests pass,
and bounded review finds no blocker.

Verification gaps:
- Implementation and verification pending.

Tests run:
- Selection only; implementation verification pending.

Behavior/schema changes:
None.

Last completed slice:
Schema branch-event callback ownership cleanup published as `43fe597e`: five
positions now point directly to `BranchEventContracts`, two pure facade
delegates were removed, 182 schema/export tests passed, full export bytes stayed
exact, and bounded review was clean.

Next candidate:
After this boundary, audit the remaining source-window lineage and report-count
delegates by owner and capture count before selecting another responsibility.

Blocked:
No.
