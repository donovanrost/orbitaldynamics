# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema scoped-downlink callback ownership cleanup.

Status:
Completed and published.

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
- None for this slice.

Tests run:
- `mix compile --warnings-as-errors`
- 11 focused strategy, cadence, and operator-review tests
- 182 complete schema-contract and schema-export tests
- full checked-in schema export regeneration; no schema diff
- aggregate schema bundle digest unchanged:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`
- `mix format --check-formatted`
- `git diff --check`
- compile-connected xref check for `schema.ex`
- bounded read-only review: clean, no findings

Outcome:
All three scoped-downlink positions now point directly to
`ScopedDownlinkContextContracts`. The pure facade delegate is gone, positional
and keyword callback ordering remains exact, and `schema.ex` decreased from
8,131 to 8,125 lines.

Behavior/schema changes:
None.

Last completed slice:
Schema scoped-downlink callback ownership cleanup published as `381690fe`:
three positions now point directly to `ScopedDownlinkContextContracts`, the
pure facade delegate was removed, 182 schema/export tests passed, full export
bytes stayed exact, and bounded review was clean.

Next candidate:
Point five ResourceProjection support callbacks directly at their owner
contracts: report counts, flow-summary counts, subsystem assumptions twice, and
flow projected-resource validation. Remove the four pure facade delegates.

Blocked:
No.
