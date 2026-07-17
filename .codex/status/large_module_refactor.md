# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema candidate-diff callback ownership cleanup.

Status:
Ready for implementation.

Selected slice:
Point semantic-change details, changed-fields, optional-source-window, and
optional-source-window-lineage callbacks directly at
`Schema.CandidateDiffContracts`. Remove the four pure facade delegates across
fourteen callback positions.

Why this slice:
The owner already exposes exact `/3` semantic and changed-field validators plus
exact `/4` optional field validators. The facade functions only forward their
arguments, and all fourteen uses can retain their current callback or positional
argument order without an owner API change.

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
All fourteen selected positions point directly to `CandidateDiffContracts`, the
four pure facade delegates are gone, field arguments, callback list positions,
and issue ordering remain exact, validation and schema exports remain
byte-for-byte stable, focused tests pass, and bounded review finds no blocker.

Verification gaps:
- Implementation and verification pending.

Tests run:
- Selection only; implementation verification pending.

Behavior/schema changes:
None.

Last completed slice:
Schema handoff-field callback ownership cleanup published as `0f51bf28`:
twenty-three captures now point directly to `HandoffFieldContracts`, eight pure
facade delegates were removed, 182 schema/export tests passed, full export
bytes stayed exact, and bounded review was clean.

Next candidate:
After this boundary, audit `BranchEventContracts.validate_summary_fields/3`
and the remaining scoped-context delegates by owner and capture count.

Blocked:
No.
