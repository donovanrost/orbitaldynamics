# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema candidate-diff callback ownership cleanup.

Status:
Completed and published.

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
- None for this slice.

Tests run:
- `mix compile --warnings-as-errors`
- 23 focused candidate-diff, resource, cadence, and operator-review tests
- 182 complete schema-contract and schema-export tests
- full checked-in schema export regeneration; no schema diff
- aggregate schema bundle digest unchanged:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`
- `mix format --check-formatted`
- `git diff --check`
- compile-connected xref check for `schema.ex`
- bounded read-only review: clean, no findings

Outcome:
All fourteen selected positions now point directly to `CandidateDiffContracts`.
Four pure facade delegates were removed, including the two field-aware `/4`
helpers, and `schema.ex` decreased from 8,166 to 8,144 lines.

Behavior/schema changes:
None.

Last completed slice:
Schema candidate-diff callback ownership cleanup published as `ceb1cdb3`:
fourteen positions now point directly to `CandidateDiffContracts`, four pure
facade delegates were removed, 182 schema/export tests passed, full export
bytes stayed exact, and bounded review was clean.

Next candidate:
Point the single branch-event validator and four branch-event summary-field
positions directly at `BranchEventContracts`, then remove both pure facade
delegates. Keep scoped-downlink callbacks separate.

Blocked:
No.
