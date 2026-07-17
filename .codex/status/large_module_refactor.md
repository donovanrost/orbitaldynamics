# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema branch-event callback ownership cleanup.

Status:
Ready for implementation.

Selected slice:
Point the strategy-branch event validator and four branch-event summary-field
positions directly at `Schema.BranchEventContracts`. Remove the two pure facade
delegates across five positions.

Why this slice:
The owner already exposes exact `/3` event and summary-field validators. The
facade functions only forward their arguments, while the positional strategy
callback and four summary callbacks can retain their existing slots and keys
without owner or consumer changes.

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
All five positions point directly to `BranchEventContracts`, both pure facade
delegates are gone, callback slots and list positions remain exact, validation
and schema exports remain byte-for-byte stable, focused tests pass, and bounded
review finds no blocker.

Verification gaps:
- Implementation and verification pending.

Tests run:
- Selection only; implementation verification pending.

Behavior/schema changes:
None.

Last completed slice:
Schema candidate-diff callback ownership cleanup published as `ceb1cdb3`:
fourteen positions now point directly to `CandidateDiffContracts`, four pure
facade delegates were removed, 182 schema/export tests passed, full export
bytes stayed exact, and bounded review was clean.

Next candidate:
After this boundary, retarget the three scoped-downlink context positions to
their owner if the positional strategy callback and both keyword bags remain
exact.

Blocked:
No.
