# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema ResourceProjection support callback ownership cleanup.

Status:
Completed and published.

Selected slice:
Point report counts, flow-summary counts, two subsystem-assumption callbacks,
and flow projected-resource validation directly at their ResourceProjection
owner contracts. Remove the four pure facade delegates across five positions.

Why this slice:
All four owner modules already expose exact `/3` APIs and the facade helpers
only forward arguments. The five positional callback slots remain within the
two existing ResourceProjection report pipelines; higher-level report, row, and
model-limit responsibilities stay unchanged.

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
All five positions point directly to their ResourceProjection owner contracts,
the four pure facade delegates are gone, positional callback ordering remains
exact, validation and schema exports remain byte-for-byte stable, focused tests
pass, and bounded review finds no blocker.

Verification gaps:
- None for this slice.

Tests run:
- `mix compile --warnings-as-errors`
- 7 focused ResourceProjection and provenance tests
- 182 complete schema-contract and schema-export tests
- full checked-in schema export regeneration; no schema diff
- aggregate schema bundle digest unchanged:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`
- `mix format --check-formatted`
- `git diff --check`
- compile-connected xref check for `schema.ex`
- bounded read-only review: clean, no findings

Outcome:
All five ResourceProjection support positions now point directly to their owner
contracts. Four pure facade delegates were removed, both positional callback
pipelines remain exact, and `schema.ex` decreased from 8,125 to 8,093 lines.

Behavior/schema changes:
None.

Last completed slice:
Schema ResourceProjection support callback ownership cleanup published as
`395b7249`: five positions now point directly to their owner contracts, four
pure facade delegates were removed, 182 schema/export tests passed, full export
bytes stayed exact, and bounded review was clean.

Next candidate:
Point link-capacity-summary and relay-data-path-summary contract pipelines
directly at their owner validators, then remove both pure facade delegates.

Blocked:
No.
