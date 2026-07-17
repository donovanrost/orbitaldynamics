# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema ResourceProjection support callback ownership cleanup.

Status:
Ready for implementation.

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
- Implementation and verification pending.

Tests run:
- Selection only; implementation verification pending.

Behavior/schema changes:
None.

Last completed slice:
Schema scoped-downlink callback ownership cleanup published as `381690fe`:
three positions now point directly to `ScopedDownlinkContextContracts`, the
pure facade delegate was removed, 182 schema/export tests passed, full export
bytes stayed exact, and bounded review was clean.

Next candidate:
After this boundary, audit the remaining source-window lineage and
link-capacity/relay summary delegates by owner and capture count.

Blocked:
No.
